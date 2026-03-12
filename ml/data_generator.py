"""
data_generator.py
-----------------
Generates a synthetic UPI transaction dataset with realistic distributions.
Produces 15000 records with rich feature engineering for high-accuracy training.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Seed for reproducibility
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)

# --- Constants ---
BANKS = ['SBI', 'HDFC', 'ICICI', 'Axis', 'South Indian Bank', 'Kotak', 'PNB', 'BOB', 'IPPB', 'UCO']
NETWORK_STATUS = ['Good', 'Moderate', 'Poor']
SERVER_STATUS  = ['Normal', 'Busy']
CATEGORIES     = ['Food', 'Bills', 'Travel', 'Shopping', 'Others']

# Failure probability weights by feature
NETWORK_FAILURE_PROB = {'Good': 0.05, 'Moderate': 0.22, 'Poor': 0.60}
SERVER_FAILURE_PROB  = {'Normal': 0.07, 'Busy': 0.42}

# Bank reliability (some banks have higher failure rates)
BANK_FAILURE_PROB = {
    'SBI': 0.10, 'HDFC': 0.06, 'ICICI': 0.07, 'Axis': 0.08,
    'South Indian Bank': 0.13, 'Kotak': 0.07, 'PNB': 0.15,
    'BOB': 0.14, 'IPPB': 0.16, 'UCO': 0.18,
}


def _amount_bucket(amount: float) -> str:
    """Categorise amount into risk tiers."""
    if amount < 500:
        return 'small'
    elif amount < 5000:
        return 'medium'
    elif amount < 50000:
        return 'large'
    else:
        return 'high'


def generate_dataset(n_records: int = 15000) -> pd.DataFrame:
    """
    Generate a synthetic UPI transaction dataset with rich features.

    Parameters:
        n_records (int): Number of records to generate. Default = 15000.

    Returns:
        pd.DataFrame: A DataFrame of synthetic UPI transactions.
    """
    records = []
    base_time = datetime(2024, 1, 1, 8, 0, 0)

    for i in range(n_records):
        # --- Basic identifiers ---
        transaction_id = f"TXN{100000 + i}"
        user_id        = f"USER{random.randint(1, 500)}"
        recipient_id   = f"REC{random.randint(1, 800)}"

        # --- Amount: skewed towards small amounts (realistic UPI behaviour) ---
        amount = round(np.random.lognormal(mean=5.5, sigma=1.2), 2)
        amount = min(amount, 100000)  # UPI limit cap

        # --- Time: spread across 2 years ---
        hour_offset      = random.randint(0, 17520)   # 2 years
        transaction_time = base_time + timedelta(hours=hour_offset)
        hour_of_day      = transaction_time.hour
        day_of_week      = transaction_time.weekday()  # 0=Mon … 6=Sun

        # --- Derived binary flags ---
        is_weekend   = 1 if day_of_week >= 5 else 0
        is_night     = 1 if (hour_of_day >= 22 or hour_of_day <= 5) else 0
        is_high_value = 1 if amount >= 50000 else 0
        amt_bucket   = _amount_bucket(amount)

        # --- Categorical features ---
        bank_name      = random.choice(BANKS)
        network_status = random.choices(NETWORK_STATUS, weights=[0.50, 0.30, 0.20], k=1)[0]
        server_status  = random.choices(SERVER_STATUS,  weights=[0.70, 0.30], k=1)[0]
        category       = random.choice(CATEGORIES)

        # --- Previous failures (0-5) ---
        previous_failures_count = int(np.random.choice(
            [0, 1, 2, 3, 4, 5], p=[0.60, 0.20, 0.10, 0.05, 0.03, 0.02]
        ))

        # --- Realistic failure probability using ALL features ---
        fail_prob = (
            NETWORK_FAILURE_PROB[network_status] * 0.30 +
            SERVER_FAILURE_PROB[server_status]   * 0.25 +
            BANK_FAILURE_PROB.get(bank_name, 0.10) * 0.20 +
            min(previous_failures_count * 0.05, 0.15) +
            (0.08 if is_night  else 0.0) +
            (0.06 if is_weekend else 0.0) +
            (0.04 if is_high_value else 0.0) +
            (0.05 if amt_bucket == 'high' else 0.0)
        )
        fail_prob = min(fail_prob, 0.95)

        status = 'Failure' if random.random() < fail_prob else 'Success'

        records.append({
            'transaction_id':          transaction_id,
            'user_id':                 user_id,
            'amount':                  amount,
            'transaction_time':        transaction_time,
            'hour_of_day':             hour_of_day,
            'day_of_week':             day_of_week,
            'is_weekend':              is_weekend,
            'is_night':                is_night,
            'is_high_value':           is_high_value,
            'amount_bucket':           amt_bucket,
            'bank_name':               bank_name,
            'network_status':          network_status,
            'server_status':           server_status,
            'recipient_id':            recipient_id,
            'previous_failures_count': previous_failures_count,
            'category':                category,
            'transaction_status':      status,
        })

    df = pd.DataFrame(records)
    print(f"[DataGenerator] Generated {len(df)} records.")
    print(f"[DataGenerator] Failure rate: {(df['transaction_status'] == 'Failure').mean():.2%}")
    return df


if __name__ == "__main__":
    df = generate_dataset(15000)
    print(df.head())
    print(df['transaction_status'].value_counts())
