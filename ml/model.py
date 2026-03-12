"""
model.py
--------
XGBoost model for UPI transaction failure prediction.

Replaces the previous Random Forest with XGBoost, which:
- Handles categorical-encoded features better via gradient boosting
- Has built-in regularisation to prevent overfitting
- Consistently outperforms Random Forest on tabular classification tasks

Hyperparameters are tuned for ~90% accuracy on synthetic UPI data.
"""

import numpy as np
import pandas as pd
from xgboost import XGBClassifier
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score,
    confusion_matrix, classification_report
)
from typing import Tuple


class FailurePredictionModel:
    """
    XGBoost classifier to predict UPI transaction failure.

    Attributes:
        model (XGBClassifier): The trained XGBoost model.
        is_trained (bool): Whether the model has been trained.
        feature_names (list): Feature column names from training.
    """

    def __init__(self):
        self.model = XGBClassifier(
            n_estimators      = 300,    # More trees = more stable predictions
            max_depth         = 6,      # Tuned: prevents overfitting on synthetic data
            learning_rate     = 0.1,    # Step size — balanced speed vs accuracy
            subsample         = 0.85,   # Row sampling — reduces overfitting
            colsample_bytree  = 0.85,   # Feature sampling per tree
            min_child_weight  = 5,      # Min samples in a leaf
            gamma             = 0.1,    # Min gain to make a split (regularisation)
            reg_alpha         = 0.1,    # L1 regularisation
            reg_lambda        = 1.0,    # L2 regularisation
            use_label_encoder = False,
            eval_metric       = 'logloss',
            random_state      = 42,
            n_jobs            = -1,     # Use all CPU cores
        )
        self.is_trained   = False
        self.feature_names = []

    def train(self, X_train: pd.DataFrame, y_train: pd.Series) -> None:
        """
        Train the XGBoost model.

        Parameters:
            X_train: Feature matrix (SMOTE-balanced training set)
            y_train: Target labels (0=Success, 1=Failure)
        """
        self.feature_names = list(X_train.columns)
        print(f"\n[Model] Training XGBoost with {len(X_train)} samples ({self.model.n_estimators} trees)...")
        self.model.fit(X_train, y_train)
        self.is_trained = True
        print("[Model] Training complete.")

    def evaluate(self, X_test: pd.DataFrame, y_test: pd.Series) -> dict:
        """
        Evaluate the model on the test set (pre-SMOTE, real distribution).

        Prints accuracy, precision, recall, confusion matrix, and feature importance.

        Returns:
            dict: Evaluation metrics.
        """
        if not self.is_trained:
            raise RuntimeError("Model is not trained yet. Call train() first.")

        y_pred = self.model.predict(X_test)

        acc       = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred, zero_division=0)
        recall    = recall_score(y_test, y_pred, zero_division=0)
        cm        = confusion_matrix(y_test, y_pred)

        print("\n" + "="*55)
        print("            MODEL EVALUATION REPORT (XGBoost)")
        print("="*55)
        print(f"  Accuracy  : {acc:.4f}  ({acc*100:.2f}%)")
        print(f"  Precision : {precision:.4f}")
        print(f"  Recall    : {recall:.4f}")
        print("\n  Confusion Matrix (rows=Actual, cols=Predicted):")
        print( "                 Predicted Success | Predicted Failure")
        print(f"  Actual Success      {cm[0][0]:>6}       |      {cm[0][1]:>6}")
        print(f"  Actual Failure      {cm[1][0]:>6}       |      {cm[1][1]:>6}")
        print("\n  Full Classification Report:")
        print(classification_report(y_test, y_pred, target_names=['Success', 'Failure']))

        # Feature importance
        importances = self.model.feature_importances_
        feat_imp = sorted(
            zip(self.feature_names, importances),
            key=lambda x: x[1], reverse=True
        )
        print("  Feature Importances (most → least influential):")
        for feat, imp in feat_imp:
            bar = "█" * int(imp * 50)
            print(f"    {feat:<30} {imp:.4f}  {bar}")
        print("="*55)

        return {
            'accuracy':         acc,
            'precision':        precision,
            'recall':           recall,
            'confusion_matrix': cm.tolist(),
        }

    def predict_proba(self, X: pd.DataFrame) -> Tuple[str, float]:
        """
        Predict failure probability for a single transaction.

        Parameters:
            X (pd.DataFrame): Single-row feature matrix

        Returns:
            Tuple[str, float]: (predicted_label, failure_probability)
                - predicted_label: 'Success' or 'Failure'
                - failure_probability: 0.0 to 1.0
        """
        if not self.is_trained:
            raise RuntimeError("Model is not trained yet. Call train() first.")

        proba     = self.model.predict_proba(X)[0]  # [prob_success, prob_failure]
        label     = self.model.predict(X)[0]
        label_str = 'Failure' if label == 1 else 'Success'

        return label_str, round(float(proba[1]), 4)
