"""
model.py
--------
Random Forest model for UPI transaction failure prediction.
Handles:
- Training with cross-validation
- Evaluation (accuracy, precision, recall, confusion matrix)
- Feature importance reporting
- Probability prediction for live transactions
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score,
    confusion_matrix, classification_report
)
from typing import Tuple


class FailurePredictionModel:
    """
    Random Forest classifier to predict UPI transaction failure.

    Attributes:
        model (RandomForestClassifier): The trained classifier.
        is_trained (bool): Whether the model has been trained.
    """

    def __init__(self, n_estimators: int = 100, random_state: int = 42):
        """
        Initialize Random Forest with sensible defaults for a mini-project.

        Parameters:
            n_estimators (int): Number of trees. More = more stable but slower.
            random_state (int): Seed for reproducibility.
        """
        self.model = RandomForestClassifier(
            n_estimators=n_estimators,
            max_depth=10,          # Limit depth to prevent overfitting
            min_samples_split=5,   # Minimum samples to split a node
            class_weight='balanced', # Handle class imbalance (more success than failure)
            random_state=random_state,
            n_jobs=-1              # Use all CPU cores
        )
        self.is_trained = False
        self.feature_names = []

    def train(self, X_train: pd.DataFrame, y_train: pd.Series) -> None:
        """
        Train the Random Forest model.

        Parameters:
            X_train: Feature matrix (training set)
            y_train: Target labels (0=Success, 1=Failure)
        """
        self.feature_names = list(X_train.columns)
        print(f"\n[Model] Training Random Forest with {len(X_train)} samples...")
        self.model.fit(X_train, y_train)
        self.is_trained = True
        print("[Model] Training complete.")

    def evaluate(self, X_test: pd.DataFrame, y_test: pd.Series) -> dict:
        """
        Evaluate the model on the test set.
        Prints accuracy, precision, recall, confusion matrix, and feature importance.

        Parameters:
            X_test:  Feature matrix (test set)
            y_test:  True labels

        Returns:
            dict: Dictionary of evaluation metrics.
        """
        if not self.is_trained:
            raise RuntimeError("Model is not trained yet. Call train() first.")

        y_pred = self.model.predict(X_test)

        acc       = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred, zero_division=0)
        recall    = recall_score(y_test, y_pred, zero_division=0)
        cm        = confusion_matrix(y_test, y_pred)

        print("\n" + "="*50)
        print("          MODEL EVALUATION REPORT")
        print("="*50)
        print(f"  Accuracy  : {acc:.4f}  ({acc*100:.2f}%)")
        print(f"  Precision : {precision:.4f}")
        print(f"  Recall    : {recall:.4f}")
        print("\n  Confusion Matrix (rows=Actual, cols=Predicted):")
        print(f"                 Predicted Success | Predicted Failure")
        print(f"  Actual Success      {cm[0][0]:>6}       |      {cm[0][1]:>6}")
        print(f"  Actual Failure      {cm[1][0]:>6}       |      {cm[1][1]:>6}")
        print("\n  Full Classification Report:")
        print(classification_report(y_test, y_pred, target_names=['Success', 'Failure']))

        # --- Feature Importance ---
        importances = self.model.feature_importances_
        feat_imp = sorted(
            zip(self.feature_names, importances),
            key=lambda x: x[1], reverse=True
        )
        print("  Feature Importances (most → least influential):")
        for feat, imp in feat_imp:
            bar = "█" * int(imp * 40)
            print(f"    {feat:<30} {imp:.4f}  {bar}")
        print("="*50)

        return {
            'accuracy': acc,
            'precision': precision,
            'recall': recall,
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

        proba  = self.model.predict_proba(X)[0]  # [prob_success, prob_failure]
        label  = self.model.predict(X)[0]
        label_str = 'Failure' if label == 1 else 'Success'

        # proba[1] = probability of class 1 (Failure)
        failure_prob = proba[1]
        return label_str, round(failure_prob, 4)
