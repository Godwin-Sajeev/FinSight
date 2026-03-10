"""
preprocessor.py
---------------
Handles all data preprocessing for the UPI failure prediction model:
- Feature selection
- Categorical encoding (Label Encoding)
- Missing value handling
- Train/Test split
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from typing import Tuple, Dict

# Features used for model training (excluding IDs and raw datetime)
FEATURE_COLUMNS = [
    'amount',
    'hour_of_day',
    'bank_name',
    'network_status',
    'server_status',
    'previous_failures_count',
]

TARGET_COLUMN = 'transaction_status'


class DataPreprocessor:
    """
    Preprocesses raw UPI transaction data for ML model training.
    Stores encoders so they can be reused during prediction.
    """

    def __init__(self):
        # Label encoders stored per categorical column
        self.encoders: Dict[str, LabelEncoder] = {}
        self.feature_columns = FEATURE_COLUMNS

    def fit_transform(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
        """
        Fit encoders and transform the full dataset.
        Call this during training.

        Returns:
            X (pd.DataFrame): Feature matrix
            y (pd.Series):    Target vector (0=Success, 1=Failure)
        """
        df = df.copy()

        # 1. Handle missing values
        df['amount'].fillna(df['amount'].median(), inplace=True)
        df['previous_failures_count'].fillna(0, inplace=True)
        for col in ['bank_name', 'network_status', 'server_status']:
            df[col].fillna('Unknown', inplace=True)

        # 2. Encode categorical features
        categorical_cols = ['bank_name', 'network_status', 'server_status']
        for col in categorical_cols:
            le = LabelEncoder()
            df[col] = le.fit_transform(df[col].astype(str))
            self.encoders[col] = le  # save for inference

        # 3. Encode target (Success=0, Failure=1)
        target_le = LabelEncoder()
        y = target_le.fit_transform(df[TARGET_COLUMN])
        self.encoders['target'] = target_le

        X = df[self.feature_columns]
        return X, pd.Series(y, name=TARGET_COLUMN)

    def transform_single(self, record: dict) -> pd.DataFrame:
        """
        Transform a single transaction dict for live prediction.
        Uses already-fitted encoders from training.

        Parameters:
            record (dict): A transaction with keys matching FEATURE_COLUMNS

        Returns:
            pd.DataFrame: Single-row feature matrix ready for model prediction
        """
        row = {}
        for col in self.feature_columns:
            val = record.get(col, None)

            if col in self.encoders:
                le = self.encoders[col]
                val_str = str(val) if val is not None else 'Unknown'
                # Handle unseen categories gracefully
                if val_str in le.classes_:
                    val = le.transform([val_str])[0]
                else:
                    # Assign the most frequent class index as fallback
                    val = 0
            else:
                val = float(val) if val is not None else 0.0

            row[col] = val

        return pd.DataFrame([row])


def split_data(
    X: pd.DataFrame,
    y: pd.Series,
    test_size: float = 0.20,
    random_state: int = 42
) -> Tuple:
    """
    Split features and target into train/test sets (80/20).

    Returns:
        X_train, X_test, y_train, y_test
    """
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state, stratify=y
    )
    print(f"[Preprocessor] Train size: {len(X_train)} | Test size: {len(X_test)}")
    return X_train, X_test, y_train, y_test
