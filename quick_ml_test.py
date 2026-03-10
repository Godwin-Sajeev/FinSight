"""
Quick ML test - shows all model outputs cleanly.
"""
import json
from datetime import datetime, timedelta
from ml.ml_agent import MLAgent


def show(label, result):
    print(f"  ML Predicted Label     : {result['ml_predicted_label']}")
    print(f"  ML Failure Probability : {result['ml_failure_probability']:.2%}")
    print(f"  Combined Probability   : {result['combined_failure_probability']:.2%}")
    hi = result['window_risk']['is_high_risk']
    print(f"  Window Risk            : {'YES' if hi else 'No'}")
    if hi:
        print(f"    Reason: {result['window_risk']['reason']}")
    a = result['transaction_alert']
    print(f"  Alert [{a['level']}]: {a['message']}")
    b = result['budget_alert']
    print(f"  Budget [{b['level']}]: {b['message']}")


def main():
    agent = MLAgent(monthly_budget=15000.0)
    agent.train(n_records=5000)

    # --- Prediction 1: Low Risk ---
    print("\n" + "=" * 55)
    print("  PREDICTION 1: Low Risk Transaction")
    print("=" * 55)
    r1 = agent.predict({
        'user_id': 'USER001',
        'amount': 350.00,
        'bank_name': 'HDFC',
        'network_status': 'Good',
        'server_status': 'Normal',
        'previous_failures_count': 0,
        'transaction_time': datetime.now(),
        'recipient_id': 'REC_SWIGGY',
        'category': 'Food',
        'transaction_status': 'Success',
    })
    show("Low Risk", r1)

    # --- Prediction 2: High ML Risk ---
    print("\n" + "=" * 55)
    print("  PREDICTION 2: High ML Risk Transaction")
    print("=" * 55)
    r2 = agent.predict({
        'user_id': 'USER001',
        'amount': 75000.00,
        'bank_name': 'PNB',
        'network_status': 'Poor',
        'server_status': 'Busy',
        'previous_failures_count': 4,
        'transaction_time': datetime.now(),
        'recipient_id': 'REC_UNKNOWN',
        'category': 'Shopping',
        'transaction_status': 'Failure',
    })
    show("High Risk", r2)

    # --- Prediction 3: Sliding Window Risk ---
    print("\n" + "=" * 55)
    print("  PREDICTION 3: Sliding Window High-Risk")
    print("=" * 55)
    base_time = datetime.now() - timedelta(minutes=20)
    for t in [10, 5]:
        agent.risk_analyzer.add_transaction({
            'transaction_id': f'TXN_OLD{t}',
            'user_id': 'USER002',
            'bank_name': 'South Indian Bank',
            'network_status': 'Moderate',
            'recipient_id': 'REC_SIB',
            'transaction_time': base_time - timedelta(minutes=t),
            'transaction_status': 'Failure',
        })
    r3 = agent.predict({
        'user_id': 'USER002',
        'amount': 500.00,
        'bank_name': 'South Indian Bank',
        'network_status': 'Moderate',
        'server_status': 'Normal',
        'previous_failures_count': 1,
        'transaction_time': datetime.now(),
        'recipient_id': 'REC_SIB',
        'category': 'Bills',
        'transaction_status': 'Pending',
    })
    show("Window Risk", r3)

    # --- NLP -> ML Bridge ---
    print("\n" + "=" * 55)
    print("  NLP -> ML INTEGRATION BRIDGE")
    print("=" * 55)
    nlp_output = {
        'amount': 500.0, 'type': 'credit',
        'merchant': 'JINCY T', 'date': '20-11-25',
        'time': '16:54:39', 'status': 'success',
        'mode': 'UPI', 'confidence_score': 0.67,
    }
    print("  NLP Agent Output:")
    print("    " + json.dumps(nlp_output, indent=4).replace("\n", "\n    "))
    r4 = agent.predict_from_nlp_output(
        nlp_output=nlp_output,
        bank_name='South Indian Bank',
        network_status='Good',
        server_status='Normal',
        user_id='USER_NLP',
    )
    if r4:
        print(f"\n  ML Failure Probability : {r4['combined_failure_probability']:.2%}")
        a = r4['transaction_alert']
        print(f"  Alert [{a['level']}]: {a['message']}")

    print("\n" + "=" * 55)
    print("  DEMO COMPLETE")
    print("=" * 55)


if __name__ == "__main__":
    main()
