"""
budget_insights.py
------------------
Spending analysis module for UPI transaction monitoring.

Features:
    - Total daily spend per user
    - Total monthly spend per user
    - Category-wise breakdown (Food, Bills, Travel, Shopping, Others)
    - Alert trigger when spend > 80% of user-defined monthly budget
"""

import pandas as pd
from datetime import datetime, date
from typing import Dict, Any, Optional, List


# Default monthly budget if user hasn't set one
DEFAULT_MONTHLY_BUDGET = 10000.0


class BudgetInsights:
    """
    Analyzes spending from a list of past successful transactions
    and provides budget status for a specific user.
    """

    def __init__(self, monthly_budget: float = DEFAULT_MONTHLY_BUDGET):
        """
        Parameters:
            monthly_budget (float): User-defined monthly spending limit in INR.
        """
        self.monthly_budget = monthly_budget
        # History: list of successful transaction dicts
        self._transactions: List[Dict[str, Any]] = []

    def add_transaction(self, transaction: Dict[str, Any]) -> None:
        """
        Add a completed SUCCESSFUL transaction to the spending history.
        Only successful transactions count toward budget.

        Parameters:
            transaction (dict): Must have 'amount', 'transaction_time',
                                'category', 'transaction_status'
        """
        if transaction.get('transaction_status') == 'Success':
            self._transactions.append(transaction)

    def get_summary(
        self,
        user_id: Optional[str]  = None,
        reference_date: Optional[date] = None
    ) -> Dict[str, Any]:
        """
        Generate spending summary.

        Parameters:
            user_id (str):          Filter by user. None = all users.
            reference_date (date):  Calculate daily/monthly totals relative to this date.
                                    Defaults to today.

        Returns:
            dict: {
                'total_daily_spend':       float,
                'total_monthly_spend':     float,
                'monthly_budget':          float,
                'monthly_spend_percentage': float,
                'category_breakdown':      dict,
                'transaction_count':       int
            }
        """
        if reference_date is None:
            reference_date = date.today()

        txns = self._transactions

        # Filter by user if specified
        if user_id:
            txns = [t for t in txns if t.get('user_id') == user_id]

        # Convert to DataFrame for easy grouping
        if not txns:
            return self._empty_summary()

        df = pd.DataFrame(txns)
        df['txn_date'] = pd.to_datetime(df['transaction_time']).dt.date
        df['txn_month'] = pd.to_datetime(df['transaction_time']).dt.to_period('M')

        ref_period = pd.Period(reference_date, freq='M')

        # --- Daily spend (only for reference_date) ---
        daily_df = df[df['txn_date'] == reference_date]
        total_daily_spend = float(daily_df['amount'].sum())

        # --- Monthly spend (full month of reference_date) ---
        monthly_df = df[df['txn_month'] == ref_period]
        total_monthly_spend = float(monthly_df['amount'].sum())

        # --- Category breakdown (monthly) ---
        if 'category' in monthly_df.columns:
            cat_breakdown = (
                monthly_df.groupby('category')['amount']
                .sum()
                .round(2)
                .to_dict()
            )
            # Ensure all standard categories are present (even if zero)
            for cat in ['Food', 'Bills', 'Travel', 'Shopping', 'Others']:
                cat_breakdown.setdefault(cat, 0.0)
        else:
            cat_breakdown = {}

        spend_pct = round((total_monthly_spend / self.monthly_budget) * 100, 2) \
                    if self.monthly_budget > 0 else None

        return {
            'total_daily_spend':        round(total_daily_spend, 2),
            'total_monthly_spend':      round(total_monthly_spend, 2),
            'monthly_budget':           self.monthly_budget,
            'monthly_spend_percentage': spend_pct,
            'category_breakdown':       cat_breakdown,
            'transaction_count':        len(monthly_df),
        }

    def _empty_summary(self) -> Dict[str, Any]:
        return {
            'total_daily_spend':        0.0,
            'total_monthly_spend':      0.0,
            'monthly_budget':           self.monthly_budget,
            'monthly_spend_percentage': 0.0,
            'category_breakdown':       {},
            'transaction_count':        0,
        }
