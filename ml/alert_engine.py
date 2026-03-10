"""
alert_engine.py
---------------
Generates human-readable alerts for UPI transactions based on:
1. ML predicted failure probability (model output)
2. Sliding window high-risk detection (risk_analyzer output)
3. Budget thresholds (budget_insights output)

Alert levels:
    HIGH  → Transaction likely to fail, immediate warning
    MEDIUM→ Elevated risk, proceed with caution
    LOW   → Transaction looks safe
"""

from typing import Dict, Any

# --- Thresholds ---
HIGH_RISK_ML_THRESHOLD    = 0.70   # ML probability above this → HIGH alert
MEDIUM_RISK_ML_THRESHOLD  = 0.40   # ML probability above this → MEDIUM alert


def generate_transaction_alert(
    failure_probability: float,
    risk_info: Dict[str, Any],
    transaction: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Generate an alert for a single transaction.

    Parameters:
        failure_probability (float): ML predicted failure probability (0.0–1.0)
                                     Already includes risk_boost from RiskAnalyzer.
        risk_info (dict):            Output from RiskAnalyzer.analyze()
        transaction (dict):          The transaction being evaluated.

    Returns:
        dict: {
            'level':   'HIGH' | 'MEDIUM' | 'LOW',
            'message': str,
            'failure_probability': float
        }
    """
    level   = 'LOW'
    message = 'Transaction looks safe. Proceed.'

    # --- Priority 1: HIGH alert ---
    if failure_probability >= HIGH_RISK_ML_THRESHOLD or risk_info.get('is_high_risk'):
        level = 'HIGH'

        reasons = []
        if failure_probability >= HIGH_RISK_ML_THRESHOLD:
            reasons.append(f"ML failure probability is high ({failure_probability:.0%})")
        if risk_info.get('is_high_risk'):
            reasons.append(risk_info.get('reason', 'Repeated failures detected in window'))

        reason_str = ". ".join(reasons)
        message = (
            f"HIGH RISK: Transaction may fail. {reason_str}. "
            f"Consider retrying later or switching bank/network."
        )

    # --- Priority 2: MEDIUM alert ---
    elif failure_probability >= MEDIUM_RISK_ML_THRESHOLD:
        level = 'MEDIUM'
        message = (
            f"MEDIUM RISK: Elevated failure probability ({failure_probability:.0%}). "
            f"Proceed carefully. If it fails, retry after a few minutes."
        )

    return {
        'level':                level,
        'message':              message,
        'failure_probability':  round(failure_probability, 4),
    }


def generate_budget_alert(budget_info: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate a budget alert based on spending analysis.

    Parameters:
        budget_info (dict): Output from BudgetInsights.get_summary()

    Returns:
        dict: {
            'level':   'WARNING' | 'OK',
            'message': str
        }
    """
    pct = budget_info.get('monthly_spend_percentage', 0)

    if pct is None:
        return {'level': 'OK', 'message': 'No budget set.'}

    if pct >= 100:
        return {
            'level': 'WARNING',
            'message': (
                f"BUDGET EXCEEDED: You have spent {pct:.1f}% of your monthly budget "
                f"(INR {budget_info['total_monthly_spend']:,.2f} / INR {budget_info['monthly_budget']:,.2f})."
            )
        }
    elif pct >= 80:
        remaining = budget_info['monthly_budget'] - budget_info['total_monthly_spend']
        return {
            'level': 'WARNING',
            'message': (
                f"BUDGET ALERT: You've used {pct:.1f}% of your monthly budget. "
                f"Only INR {remaining:,.2f} remaining. Spend wisely!"
            )
        }

    return {
        'level': 'OK',
        'message': f"Budget OK: {pct:.1f}% used (INR {budget_info['total_monthly_spend']:,.2f} of INR {budget_info['monthly_budget']:,.2f})."
    }
