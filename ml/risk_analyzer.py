"""
risk_analyzer.py
----------------
Sliding Window Risk Analysis for UPI transactions.

Concept:
    Analyze the last N minutes of transactions for a user.
    If multiple failures share the same bank, network, or recipient
    within a short window → classify the context as HIGH RISK.

This works alongside the ML model to increase signal in edge cases
where pattern-based risk is obvious even before the model fires.
"""

from datetime import datetime, timedelta
from collections import Counter
from typing import List, Dict, Any


# --- Configuration ---
WINDOW_MINUTES          = 30   # Sliding window size (last 30 minutes)
MIN_FAILURES_FOR_RISK   = 2    # Minimum failures to trigger high-risk
RISK_BOOST_PROBABILITY  = 0.25 # Additive boost to ML failure probability if high-risk


class RiskAnalyzer:
    """
    Analyzes a history of recent transactions using a sliding time window
    to detect high-risk patterns (repeated failures on same bank/network/recipient).

    Usage:
        analyzer = RiskAnalyzer()
        analyzer.add_transaction(txn_dict)
        risk_info = analyzer.analyze(current_transaction)
    """

    def __init__(self, window_minutes: int = WINDOW_MINUTES):
        self.window_minutes = window_minutes
        # Internal history: list of transaction dicts (stored in memory)
        self._history: List[Dict[str, Any]] = []

    def add_transaction(self, transaction: Dict[str, Any]) -> None:
        """
        Record a completed transaction into history.

        Parameters:
            transaction (dict): Must contain 'transaction_time' (datetime),
                                'transaction_status', 'bank_name',
                                'network_status', 'recipient_id'
        """
        self._history.append(transaction)

    def _get_recent_failures(self, reference_time: datetime) -> List[Dict]:
        """
        Return all FAILED transactions within the sliding window
        before reference_time.
        """
        cutoff = reference_time - timedelta(minutes=self.window_minutes)
        return [
            t for t in self._history
            if t.get('transaction_status') == 'Failure'
            and isinstance(t.get('transaction_time'), datetime)
            and cutoff <= t['transaction_time'] <= reference_time
        ]

    def analyze(self, current_txn: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze whether the current transaction is in a high-risk window.

        Algorithm:
            1. Fetch recent failures in the last N minutes.
            2. Check if >= MIN_FAILURES_FOR_RISK failures share:
               - same bank_name, OR
               - same network_status, OR
               - same recipient_id
            3. If yes → HIGH RISK, return reason + probability boost.

        Parameters:
            current_txn (dict): The transaction being evaluated.

        Returns:
            dict: {
                'is_high_risk': bool,
                'reason': str,
                'risk_boost': float,    # Additive probability boost
                'failure_count_in_window': int
            }
        """
        ref_time = current_txn.get('transaction_time', datetime.now())
        recent_failures = self._get_recent_failures(ref_time)
        n_failures = len(recent_failures)

        result = {
            'is_high_risk': False,
            'reason': 'No repeated failures in recent window.',
            'risk_boost': 0.0,
            'failure_count_in_window': n_failures,
        }

        if n_failures < MIN_FAILURES_FOR_RISK:
            return result

        reasons = []

        # --- Check: same bank ---
        bank_counts = Counter(t['bank_name'] for t in recent_failures if 'bank_name' in t)
        same_bank = current_txn.get('bank_name')
        if same_bank and bank_counts.get(same_bank, 0) >= MIN_FAILURES_FOR_RISK:
            reasons.append(f"bank '{same_bank}' had {bank_counts[same_bank]} recent failures")

        # --- Check: same network ---
        net_counts = Counter(t['network_status'] for t in recent_failures if 'network_status' in t)
        same_net = current_txn.get('network_status')
        if same_net and net_counts.get(same_net, 0) >= MIN_FAILURES_FOR_RISK:
            reasons.append(f"network '{same_net}' had {net_counts[same_net]} recent failures")

        # --- Check: same recipient ---
        rec_counts = Counter(t['recipient_id'] for t in recent_failures if 'recipient_id' in t)
        same_rec = current_txn.get('recipient_id')
        if same_rec and rec_counts.get(same_rec, 0) >= MIN_FAILURES_FOR_RISK:
            reasons.append(f"recipient '{same_rec}' had {rec_counts[same_rec]} recent failures")

        if reasons:
            result['is_high_risk'] = True
            result['reason'] = "High-risk window detected: " + "; ".join(reasons)
            result['risk_boost'] = RISK_BOOST_PROBABILITY

        return result
