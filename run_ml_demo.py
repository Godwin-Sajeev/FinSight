"""
run_ml_demo.py
--------------
End-to-end demonstration of the Smart UPI Transaction Monitoring ML system.

What this demo does:
    1. Trains the Random Forest model on 5000 synthetic UPI records
    2. Prints full model evaluation (accuracy, precision, recall, confusion matrix)
    3. Runs 3 example predictions (Low Risk, High ML Risk, High Window Risk)
    4. Shows budget analysis with alert at >80% spend
    5. Demonstrates the NLP → ML integration bridge

Run:
    python run_ml_demo.py
"""

import json
from datetime import datetime, timedelta
from ml.ml_agent import MLAgent


def print_section(title: str) -> None:
    print(f"\n{'='*55}")
    print(f"  {title}")
    print(f"{'='*55}")


def print_result(result: dict) -> None:
    """Pretty-print a prediction result."""
    txn_alert    = result['transaction_alert']
    budget_alert = result['budget_alert']

    print(f"  ML Predicted Label     : {result['ml_predicted_label']}")
    print(f"  ML Failure Probability : {result['ml_failure_probability']:.2%}")
    print(f"  Combined Probability   : {result['combined_failure_probability']:.2%}")
    print(f"  Window Risk            : {'YES ⚠' if result['window_risk']['is_high_risk'] else 'No'}")
    if result['window_risk']['is_high_risk']:
        print(f"    Reason: {result['window_risk']['reason']}")
    print(f"\n  🔔 TRANSACTION ALERT [{txn_alert['level']}]:")
    print(f"     {txn_alert['message']}")
    print(f"\n  💰 BUDGET ALERT [{budget_alert['level']}]:")
    print(f"     {budget_alert['message']}")


def main():
    # ----------------------------------------------------------------
    # STEP 1: Initialize and Train
    # ----------------------------------------------------------------
    agent = MLAgent(monthly_budget=15000.0)  # User's monthly budget: ₹15,000
    agent.train(n_records=5000)

    # ----------------------------------------------------------------
    # STEP 2: Example Prediction 1 — LOW RISK transaction
    # ----------------------------------------------------------------
    print_section("PREDICTION 1: Low Risk Transaction")

    low_risk_txn = {
        'user_id':                'USER001',
        'amount':                 350.00,
        'bank_name':              'HDFC',
        'network_status':         'Good',
        'server_status':          'Normal',
        'previous_failures_count': 0,
        'transaction_time':       datetime.now(),
        'recipient_id':           'REC_SWIGGY',
        'category':               'Food',
        'transaction_status':     'Success',
    }
    result1 = agent.predict(low_risk_txn)
    print_result(result1)

    # ----------------------------------------------------------------
    # STEP 3: Example Prediction 2 — HIGH ML RISK transaction
    # ----------------------------------------------------------------
    print_section("PREDICTION 2: High ML Risk Transaction")

    high_risk_txn = {
        'user_id':                'USER001',
        'amount':                 75000.00,        # Large amount
        'bank_name':              'PNB',
        'network_status':         'Poor',          # Bad network
        'server_status':          'Busy',          # Busy server
        'previous_failures_count': 4,              # History of failures
        'transaction_time':       datetime.now(),
        'recipient_id':           'REC_UNKNOWN',
        'category':               'Shopping',
        'transaction_status':     'Failure',       # Simulated as failed
    }
    result2 = agent.predict(high_risk_txn)
    print_result(result2)

    # ----------------------------------------------------------------
    # STEP 4: Example Prediction 3 — HIGH WINDOW RISK
    # (Simulate repeated failures on same bank within 30 min window)
    # ----------------------------------------------------------------
    print_section("PREDICTION 3: Sliding Window High-Risk Detection")

    base_time = datetime.now() - timedelta(minutes=20)

    # Inject 2 past failures on same bank into the risk analyzer's history
    past_failures = [
        {
            'transaction_id':     'TXN_OLD1',
            'user_id':            'USER002',
            'bank_name':          'South Indian Bank',
            'network_status':     'Moderate',
            'recipient_id':       'REC_SIB_MERCHANT',
            'transaction_time':   base_time - timedelta(minutes=10),
            'transaction_status': 'Failure',
        },
        {
            'transaction_id':     'TXN_OLD2',
            'user_id':            'USER002',
            'bank_name':          'South Indian Bank',
            'network_status':     'Moderate',
            'recipient_id':       'REC_SIB_MERCHANT',
            'transaction_time':   base_time - timedelta(minutes=5),
            'transaction_status': 'Failure',
        },
    ]
    for f in past_failures:
        agent.risk_analyzer.add_transaction(f)

    # Now predict for a similar transaction
    window_risk_txn = {
        'user_id':                'USER002',
        'amount':                 500.00,
        'bank_name':              'South Indian Bank',  # Same bank as recent failures!
        'network_status':         'Moderate',
        'server_status':          'Normal',
        'previous_failures_count': 1,
        'transaction_time':       datetime.now(),
        'recipient_id':           'REC_SIB_MERCHANT',
        'category':               'Bills',
        'transaction_status':     'Pending',
    }
    result3 = agent.predict(window_risk_txn)
    print_result(result3)

    # ----------------------------------------------------------------
    # STEP 5: Budget Analysis
    # ----------------------------------------------------------------
    print_section("BUDGET ANALYSIS — Monthly Spend Breakdown")

    # Add several successful transactions to hit 80%+ of budget
    spend_txns = [
        ('Food', 2500.0), ('Bills', 4000.0),
        ('Travel', 2000.0), ('Shopping', 3800.0), ('Others', 1200.0)
    ]
    for cat, amt in spend_txns:
        agent.budget_insights.add_transaction({
            'user_id':            'USER001',
            'amount':             amt,
            'category':           cat,
            'transaction_time':   datetime.now(),
            'transaction_status': 'Success',
        })

    budget_summary = agent.budget_insights.get_summary(user_id='USER001')
    budget_alert   = __import__('ml.alert_engine', fromlist=['generate_budget_alert']).generate_budget_alert(budget_summary)

    print(f"  Monthly Budget         : ₹{budget_summary['monthly_budget']:,.2f}")
    print(f"  Total Monthly Spend    : ₹{budget_summary['total_monthly_spend']:,.2f}")
    print(f"  Budget Used            : {budget_summary['monthly_spend_percentage']:.1f}%")
    print(f"\n  Category Breakdown:")
    for cat, amt in budget_summary['category_breakdown'].items():
        bar = "█" * int(amt / 500)
        print(f"    {cat:<12} ₹{amt:>8,.2f}  {bar}")
    print(f"\n  💰 BUDGET ALERT [{budget_alert['level']}]:")
    print(f"     {budget_alert['message']}")

    # ----------------------------------------------------------------
    # STEP 6: NLP → ML Integration Demo
    # ----------------------------------------------------------------
    print_section("NLP → ML INTEGRATION BRIDGE DEMO")

    # This is what the NLP agent produces from an SMS
    sample_nlp_output = {
        'amount':     500.0,
        'type':       'credit',
        'merchant':   'JINCY T',
        'date':       '20-11-25',
        'time':       '16:54:39',
        'status':     'success',
        'mode':       'UPI',
        'confidence_score': 0.67,
    }

    print("  NLP Agent Output (from SMS parsing):")
    print(f"    {json.dumps(sample_nlp_output, indent=4)}")

    ml_result = agent.predict_from_nlp_output(
        nlp_output=sample_nlp_output,
        bank_name='South Indian Bank',
        network_status='Good',
        server_status='Normal',
        user_id='USER_NLP',
    )

    if ml_result:
        print(f"\n  ML Agent Output:")
        print(f"    Failure Probability : {ml_result['combined_failure_probability']:.2%}")
        print(f"    Alert               : [{ml_result['transaction_alert']['level']}] {ml_result['transaction_alert']['message']}")
    
    print_section("DEMO COMPLETE ✅")


if __name__ == "__main__":
    main()
