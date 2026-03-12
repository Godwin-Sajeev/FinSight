"""
preprocessor.py
---------------
Handles all data preprocessing for the UPI failure prediction model:
- Feature engineering (11 features total)
- Ordinal encoding for categorical features
- SMOTE oversampling to fix class imbalance
- Train/Test split
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OrdinalEncoder
from imblearn.over_sampling import SMOTE
from typing import Tuple, Dict

# ── feature columns ─────────────────────────────────────────────────────────
FEATURE_COLUMNS = [
    # Original features
    'amount',
    'hour_of_day',
    'bank_name',
    'network_status',
    'server_status',
    'previous_failures_count',
    # New engineered features
    'day_of_week',
    'is_weekend',
    'is_night',
    'is_high_value',
    'amount_bucket',
]

CATEGORICAL_COLS = ['bank_name', 'network_status', 'server_status', 'amount_bucket']
TARGET_COLUMN    = 'transaction_status'

# Known category values for OrdinalEncoder
CATEGORY_VALUES = {
    'bank_name':      [['SBI', 'HDFC', 'ICICI', 'Axis', 'South Indian Bank',
                        'Kotak', 'PNB', 'BOB', 'IPPB', 'UCO', 'Unknown']],
    'network_status': [['Good', 'Moderate', 'Poor', 'Unknown']],
    'server_status':  [['Normal', 'Busy', 'Unknown']],
    'amount_bucket':  [['small', 'medium', 'large', 'high', 'Unknown']],
}


def _amount_bucket(amount: float) -> str:
    if amount < 500:    return 'small'
    if amount < 5000:   return 'medium'
    if amount < 50000:  return 'large'
    return 'high'


class DataPreprocessor:
    """Preprocesses raw UPI transaction data for XGBoost model training."""

    def __init__(self):
        self.encoders: Dict[str, OrdinalEncoder] = {}
        self.feature_columns = FEATURE_COLUMNS

    # ── training path ────────────────────────────────────────────────────────
    def fit_transform(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
        """
        Fit encoders and transform the full dataset. Applies SMOTE oversampling.
        Call this during training only.

        Returns:
            X (pd.DataFrame): Balanced feature matrix
            y (pd.Series):    Balanced target vector (0=Success, 1=Failure)
        """
        df = df.copy()

        # ── 1. Engineer new features (may already exist from generator) ──────
        if 'day_of_week' not in df.columns:
            df['transaction_time'] = pd.to_datetime(df['transaction_time'])
            df['day_of_week']  = df['transaction_time'].dt.dayofweek
            df['is_weekend']   = (df['day_of_week'] >= 5).astype(int)
            df['is_night']     = ((df['hour_of_day'] >= 22) | (df['hour_of_day'] <= 5)).astype(int)
            df['is_high_value'] = (df['amount'] >= 50000).astype(int)
            df['amount_bucket'] = df['amount'].apply(_amount_bucket)

        # ── 2. Fill missing values ────────────────────────────────────────────
        df['amount']                 = df['amount'].fillna(df['amount'].median())
        df['previous_failures_count'] = df['previous_failures_count'].fillna(0)
        df['day_of_week']            = df['day_of_week'].fillna(0)
        df['is_weekend']             = df['is_weekend'].fillna(0)
        df['is_night']               = df['is_night'].fillna(0)
        df['is_high_value']          = df['is_high_value'].fillna(0)
        for col in CATEGORICAL_COLS:
            df[col] = df[col].fillna('Unknown')

        # ── 3. Ordinal-encode categorical features ────────────────────────────
        for col in CATEGORICAL_COLS:
            enc = OrdinalEncoder(
                categories=CATEGORY_VALUES[col],
                handle_unknown='use_encoded_value',
                unknown_value=-1,
            )
            df[col] = enc.fit_transform(df[[col]])
            self.encoders[col] = enc

        # ── 4. Encode target (Failure=1, Success=0) ───────────────────────────
        y = (df[TARGET_COLUMN] == 'Failure').astype(int)

        X = df[self.feature_columns].copy()

        # ── 5. SMOTE — balance the class distribution ─────────────────────────
        print(f"[Preprocessor] Before SMOTE — Class distribution: {dict(y.value_counts())}")
        smote = SMOTE(random_state=42)
        X_res, y_res = smote.fit_resample(X, y)
        print(f"[Preprocessor] After SMOTE  — Class distribution: {dict(pd.Series(y_res).value_counts())}")

        return pd.DataFrame(X_res, columns=self.feature_columns), pd.Series(y_res, name=TARGET_COLUMN)

    # ── inference path ───────────────────────────────────────────────────────
    def transform_single(self, record: dict) -> pd.DataFrame:
        """
        Transform a single transaction dict for live prediction.
        Computes all engineered features automatically from raw values.

        Parameters:
            record (dict): A transaction dict with raw keys.

        Returns:
            pd.DataFrame: Single-row feature matrix ready for XGBoost.
        """
        from datetime import datetime as dt

        rec = record.copy()

        # ── Compute derived features ─────────────────────────────────────────
        txn_time  = rec.get('transaction_time', dt.now())
        hour      = rec.get('hour_of_day', txn_time.hour if hasattr(txn_time, 'hour') else 12)
        dow       = txn_time.weekday() if hasattr(txn_time, 'weekday') else 0
        amount    = float(rec.get('amount', 0.0))

        rec.setdefault('day_of_week',   dow)
        rec.setdefault('is_weekend',    1 if dow >= 5 else 0)
        rec.setdefault('is_night',      1 if (hour >= 22 or hour <= 5) else 0)
        rec.setdefault('is_high_value', 1 if amount >= 50000 else 0)
        rec.setdefault('amount_bucket', _amount_bucket(amount))

        row = {}
        for col in self.feature_columns:
            val = rec.get(col, None)

            if col in self.encoders:
                enc     = self.encoders[col]
                val_str = str(val) if val is not None else 'Unknown'
                # Pass as DataFrame with column name to match fit-time feature names
                val = enc.transform(pd.DataFrame([[val_str]], columns=[col]))[0][0]
            else:
                val = float(val) if val is not None else 0.0

            row[col] = val

        return pd.DataFrame([row])


def split_data(
    X: pd.DataFrame,
    y: pd.Series,
    test_size: float = 0.20,
    random_state: int = 42,
) -> Tuple:
    """Split features and target into train/test sets (80/20 stratified)."""
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state, stratify=y
    )
    print(f"[Preprocessor] Train size: {len(X_train)} | Test size: {len(X_test)}")
    return X_train, X_test, y_train, y_test
