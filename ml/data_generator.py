"""
data_generator.py
-----------------
Generates a synthetic UPI transaction dataset with realistic distributions.
Produces 5000+ records suitable for training a failure prediction model.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Seed for reproducibility
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)

# --- Constants for realistic data ---
BANKS = ['SBI', 'HDFC', 'ICICI', 'Axis', 'South Indian Bank', 'Kotak', 'PNB', 'BOB']
NETWORK_STATUS = ['Good', 'Moderate', 'Poor']
SERVER_STATUS = ['Normal', 'Busy']
CATEGORIES = ['Food', 'Bills', 'Travel', 'Shopping', 'Others']

# Failure probability weights by feature (used to make data realistic)
NETWORK_FAILURE_PROB = {'Good': 0.05, 'Moderate': 0.20, 'Poor': 0.55}
SERVER_FAILURE_PROB  = {'Normal': 0.08, 'Busy': 0.40}


def generate_dataset(n_records: int = 5000) -> pd.DataFrame:
    """
    Generate a synthetic UPI transaction dataset.

    Parameters:
        n_records (int): Number of records to generate. Default = 5000.

    Returns:
        pd.DataFrame: A DataFrame of synthetic UPI transactions.
    """
    records = []
    base_time = datetime(2025, 1, 1, 8, 0, 0)

    for i in range(n_records):
        # --- Basic identifiers ---
        transaction_id = f"TXN{100000 + i}"
        user_id        = f"USER{random.randint(1, 300)}"
        recipient_id   = f"REC{random.randint(1, 500)}"

        # --- Amount: skewed towards small amounts (realistic UPI behaviour) ---
        amount = round(np.random.lognormal(mean=5.5, sigma=1.2), 2)
        amount = min(amount, 100000)  # UPI limit cap

        # --- Time: spread across day/night (more failures at night = busy server) ---
        hour_offset = random.randint(0, 8760)  # spread over a year
        transaction_time = base_time + timedelta(hours=hour_offset)
        hour_of_day = transaction_time.hour

        # --- Categorical features ---
        bank_name      = random.choice(BANKS)
        network_status = random.choices(
            NETWORK_STATUS, weights=[0.50, 0.30, 0.20], k=1
        )[0]
        server_status  = random.choices(
            SERVER_STATUS, weights=[0.70, 0.30], k=1
        )[0]
        category       = random.choice(CATEGORIES)

        # --- Previous failures count (0-5, most users have 0) ---
        previous_failures_count = int(np.random.choice(
            [0, 1, 2, 3, 4, 5], p=[0.60, 0.20, 0.10, 0.05, 0.03, 0.02]
        ))

        # --- Determine transaction status (realistic failure logic) ---
        # Base failure probability from network + server
        fail_prob = (
            NETWORK_FAILURE_PROB[network_status] * 0.45 +
            SERVER_FAILURE_PROB[server_status]   * 0.35 +
            min(previous_failures_count * 0.05, 0.15) +   # history of failures
            (0.05 if hour_of_day >= 22 or hour_of_day <= 5 else 0.0) +  # late night
            (0.03 if amount > 50000 else 0.0)              # high-value risk
        )
        fail_prob = min(fail_prob, 0.95)  # cap at 95%

        status = 'Failure' if random.random() < fail_prob else 'Success'

        records.append({
            'transaction_id':         transaction_id,
            'user_id':                user_id,
            'amount':                 amount,
            'transaction_time':       transaction_time,
            'hour_of_day':            hour_of_day,
            'bank_name':              bank_name,
            'network_status':         network_status,
            'server_status':          server_status,
            'recipient_id':           recipient_id,
            'previous_failures_count': previous_failures_count,
            'category':               category,
            'transaction_status':     status,
        })

    df = pd.DataFrame(records)
    print(f"[DataGenerator] Generated {len(df)} records.")
    print(f"[DataGenerator] Failure rate: {(df['transaction_status'] == 'Failure').mean():.2%}")
    return df


if __name__ == "__main__":
    df = generate_dataset(5000)
    print(df.head())
    print(df['transaction_status'].value_counts())
