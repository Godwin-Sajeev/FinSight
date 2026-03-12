"""
ml_agent.py
-----------
Main ML Orchestrator for the Smart UPI Transaction Monitoring system.

This is the single entry point that:
    1. Trains the Random Forest model on synthetic data (first run)
    2. Accepts a new transaction dict
    3. Runs ML failure prediction
    4. Runs sliding window risk analysis
    5. Combines both signals into a final failure probability
    6. Generates alerts
    7. Updates budget tracking

Integration point with NLP Agent:
    The NLP agent (src/nlp_agent.py) produces a dict like:
        {
            'amount': 500.0,
            'type': 'credit',
            'merchant': 'JINCY T',
            'date': '20-11-25',
            ...
        }
    This MLAgent.predict_from_nlp_output() method accepts that dict
    and maps it to the ML feature space automatically.
"""

import json
from datetime import datetime
from typing import Dict, Any, Optional

from .data_generator  import generate_dataset
from .preprocessor    import DataPreprocessor, split_data
from .model           import FailurePredictionModel
from .risk_analyzer   import RiskAnalyzer
from .alert_engine    import generate_transaction_alert, generate_budget_alert
from .budget_insights import BudgetInsights


class MLAgent:
    """
    End-to-end ML agent for UPI transaction monitoring.

    Lifecycle:
        agent = MLAgent(monthly_budget=15000)
        agent.train()                          # Train model on synthetic data
        result = agent.predict(transaction)    # Predict risk for a transaction
    """

    def __init__(self, monthly_budget: float = 10000.0):
        self.preprocessor    = DataPreprocessor()
        self.model           = FailurePredictionModel()
        self.risk_analyzer   = RiskAnalyzer()
        self.budget_insights = BudgetInsights(monthly_budget=monthly_budget)
        self._trained        = False

    # ------------------------------------------------------------------
    # TRAINING
    # ------------------------------------------------------------------

    def train(self, n_records: int = 15000) -> None:
        """
        Generate synthetic data, preprocess, and train the Random Forest model.

        Parameters:
            n_records (int): Number of synthetic UPI records to generate.
        """
        print("\n" + "="*50)
        print("  SMART UPI MONITORING — TRAINING PIPELINE")
        print("="*50)

        # Step 1: Generate dataset
        df = generate_dataset(n_records)

        # Step 2: Preprocess
        X, y = self.preprocessor.fit_transform(df)

        # Step 3: Split
        X_train, X_test, y_train, y_test = split_data(X, y)

        # Step 4: Train
        self.model.train(X_train, y_train)

        # Step 5: Evaluate
        self.model.evaluate(X_test, y_test)

        self._trained = True
        print("\n[MLAgent] System ready for predictions.\n")

    # ------------------------------------------------------------------
    # PREDICTION
    # ------------------------------------------------------------------

    def predict(self, transaction: Dict[str, Any]) -> Dict[str, Any]:
        """
        Full prediction pipeline for a single UPI transaction.

        Parameters:
            transaction (dict): Must contain at minimum:
                - amount (float)
                - hour_of_day (int)
                - bank_name (str)
                - network_status (str): 'Good' | 'Moderate' | 'Poor'
                - server_status (str):  'Normal' | 'Busy'
                - previous_failures_count (int)
                Optional (for risk window + budget):
                - transaction_time (datetime)
                - user_id, recipient_id, category, transaction_status

        Returns:
            dict: Full prediction result with alert and budget info.
        """
        if not self._trained:
            raise RuntimeError("Model not trained. Call agent.train() first.")

        # Default transaction_time if not provided
        if 'transaction_time' not in transaction:
            transaction['transaction_time'] = datetime.now()
        if 'hour_of_day' not in transaction:
            transaction['hour_of_day'] = transaction['transaction_time'].hour

        # --- Step 1: ML Prediction ---
        X = self.preprocessor.transform_single(transaction)
        predicted_label, ml_failure_prob = self.model.predict_proba(X)

        # --- Step 2: Sliding Window Risk Analysis ---
        risk_info = self.risk_analyzer.analyze(transaction)

        # --- Step 3: Combine ML + Window Risk ---
        # Additive: if window detects high risk, boost failure probability
        combined_prob = min(ml_failure_prob + risk_info.get('risk_boost', 0.0), 1.0)

        # --- Step 4: Generate Transaction Alert ---
        txn_alert = generate_transaction_alert(combined_prob, risk_info, transaction)

        # --- Step 5: Update Budget (if it's a successful transaction) ---
        self.budget_insights.add_transaction(transaction)

        # --- Step 6: Budget Alert ---
        budget_summary = self.budget_insights.get_summary(
            user_id=transaction.get('user_id')
        )
        budget_alert = generate_budget_alert(budget_summary)

        # --- Compile Final Result ---
        result = {
            'input_transaction':    transaction,
            'ml_predicted_label':   predicted_label,
            'ml_failure_probability': ml_failure_prob,
            'combined_failure_probability': combined_prob,
            'window_risk':          risk_info,
            'transaction_alert':    txn_alert,
            'budget_summary':       budget_summary,
            'budget_alert':         budget_alert,
        }

        # Record in history for future window analysis
        self.risk_analyzer.add_transaction(transaction)

        return result

    # ------------------------------------------------------------------
    # NLP INTEGRATION BRIDGE
    # ------------------------------------------------------------------

    def predict_from_nlp_output(
        self,
        nlp_output: Dict[str, Any],
        bank_name: str = 'Unknown',
        network_status: str = 'Good',
        server_status: str = 'Normal',
        user_id: str = 'USER_DEFAULT',
    ) -> Optional[Dict[str, Any]]:
        """
        Bridge method: accepts output from the NLP agent (src/nlp_agent.py)
        and converts it into an ML-compatible transaction dict.

        This enables full NLP → ML pipeline integration.

        Parameters:
            nlp_output (dict):     Output from UPIAgent.process_message()
            bank_name (str):       Bank name (not extracted by NLP currently)
            network_status (str):  Network quality hint
            server_status (str):   Server status hint
            user_id (str):         User identifier

        Returns:
            dict: Full ML prediction result, or None if NLP output is invalid.
        """
        if not nlp_output or nlp_output.get('amount') is None:
            return None

        # Map NLP output to ML feature format
        transaction = {
            'amount':                  nlp_output.get('amount', 0.0),
            'bank_name':               bank_name,
            'network_status':          network_status,
            'server_status':           server_status,
            'previous_failures_count': 0,  # Default; can be tracked over sessions
            'transaction_time':        datetime.now(),
            'user_id':                 user_id,
            'recipient_id':            nlp_output.get('merchant', 'Unknown'),
            'category':                'Others',
            'transaction_status':      'Success' if nlp_output.get('type') == 'credit' else 'Pending',
        }

        return self.predict(transaction)
