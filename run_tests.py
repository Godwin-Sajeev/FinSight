"""
run_tests.py
------------
End-to-end verification script for the entire Smart UPI Monitoring system.
Tests: Sender Validation, NLP Pipeline, NLP->ML Integration, Budget Insights.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

PASS = 0
FAIL = 0

def check(label, condition, got=""):
    global PASS, FAIL
    if condition:
        print(f"  [PASS] {label}")
        PASS += 1
    else:
        print(f"  [FAIL] {label}  -> got: {got}")
        FAIL += 1

def section(title):
    print(f"\n{'='*55}")
    print(f"  {title}")
    print(f"{'='*55}")


# ============================================================
# 1. SENDER VALIDATOR
# ============================================================
section("1. Sender Validator")
from nlp.sender_validator import SenderValidator
v = SenderValidator()

r = v.validate("VM-SBIUPI")
check("SBI sender valid",       r['is_valid'] and r['bank_name'] == 'SBI')

r = v.validate("JD-IPBMSG-S")
check("IPPB sender valid",      r['is_valid'] and r['bank_name'] == 'IPPB')

r = v.validate("VK-ICICIB")
check("ICICI sender valid",     r['is_valid'] and r['bank_name'] == 'ICICI')

r = v.validate("AM-HDFCBK")
check("HDFC sender valid",      r['is_valid'] and r['bank_name'] == 'HDFC')

r = v.validate("BP-AXISBK")
check("Axis sender valid",      r['is_valid'] and r['bank_name'] == 'Axis')

r = v.validate("XX-SPAM01")
check("Spam sender rejected",   not r['is_valid'] and r['bank_name'] is None)

r = v.validate("vm-sbiupi")
check("Case-insensitive match", r['is_valid'] and r['bank_name'] == 'SBI')

r = v.validate("")
check("Empty sender rejected",  not r['is_valid'])


# ============================================================
# 2. NLP PIPELINE
# ============================================================
section("2. NLP Pipeline")
from nlp.nlp_agent import UPIAgent
agent = UPIAgent()

# 2a. Valid sender + debit SMS
r = agent.process_message(
    "Rs.1250 debited from your account via UPI to Swiggy on 14/01/2026 at 8:43 PM.",
    sender_id="VM-SBIUPI"
)
check("SBI debit parsed",       r is not None and r['amount'] == 1250.0,  r)
check("SBI bank_name attached", r is not None and r['bank_name'] == 'SBI', r)
check("Debit type detected",    r is not None and r['type'] == 'debit',    r)

# 2b. IPPB sender
r = agent.process_message(
    "A/C X4952 Debit Rs.100.00 for UPI to Generic User on 12-01-26 Ref 601202411884-IPPB",
    sender_id="JD-IPBMSG-S"
)
check("IPPB debit parsed",      r is not None and r['amount'] == 100.0,    r)
check("IPPB bank_name attached",r is not None and r['bank_name'] == 'IPPB', r)

# 2c. Spam sender rejected
r = agent.process_message("Rs.500 debited to Swiggy via UPI.", sender_id="XX-SPAM01")
check("Spam sender rejected",   r is None, r)

# 2d. OTP filtered even with valid sender
r = agent.process_message("Your OTP is 123456. Do not share.", sender_id="AM-HDFCBK")
check("OTP intent filtered",    r is None, r)

# 2e. Failed transaction detected
r = agent.process_message("Transaction of Rs.200 to Uber failed due to insufficient funds.")
check("Failed txn status",      r is not None and r['status'] == 'failed', r)

# 2f. Credit transaction
r = agent.process_message("Your account is credited with Rs 500.00 from John Doe on 15-01-26.")
check("Credit type detected",   r is not None and r['type'] == 'credit', r)

# 2g. No sender (backward compat)
r = agent.process_message("Rs.1250 debited from your account via UPI to Swiggy on 14/01/2026.")
check("No sender backward compat", r is not None and r['sender_id'] is None, r)


# ============================================================
# 3. ML PIPELINE
# ============================================================
section("3. ML Pipeline (Training + Prediction)")
from ml.ml_agent import MLAgent

ml_agent = MLAgent(monthly_budget=15000.0)
ml_agent.train(n_records=1000)  # small for speed

transaction = {
    'amount':                  500.0,
    'bank_name':               'SBI',
    'network_status':          'Good',
    'server_status':           'Normal',
    'previous_failures_count': 0,
    'user_id':                 'USER001',
    'recipient_id':            'Swiggy',
    'category':                'Food',
    'transaction_status':      'Success',
}
result = ml_agent.predict(transaction)

check("ML prediction returned",       result is not None)
check("Failure prob in range [0,1]",  0.0 <= result['ml_failure_probability'] <= 1.0,
      result.get('ml_failure_probability'))
check("Combined prob in range [0,1]", 0.0 <= result['combined_failure_probability'] <= 1.0)
check("Alert level present",          result['transaction_alert']['level'] in ('LOW','MEDIUM','HIGH'))
check("Budget summary present",       result['budget_summary']['monthly_budget'] == 15000.0)


# ============================================================
# 4. NLP -> ML BRIDGE
# ============================================================
section("4. NLP -> ML Integration Bridge")
nlp_out = agent.process_message(
    "Rs.800 debited from your account via UPI to Amazon on 10/03/2026.",
    sender_id="AM-HDFCBK"
)
check("NLP output valid",   nlp_out is not None and nlp_out['amount'] == 800.0, nlp_out)

bridge_result = ml_agent.predict_from_nlp_output(
    nlp_out,
    bank_name=nlp_out.get('bank_name', 'HDFC'),
    network_status='Good',
    server_status='Normal',
    user_id='USER_TEST',
)
check("NLP->ML bridge result",        bridge_result is not None)
check("Bridge failure prob valid",    bridge_result is not None and
      0.0 <= bridge_result['ml_failure_probability'] <= 1.0)
check("Bridge budget summary present",bridge_result is not None and
      'budget_summary' in bridge_result)


# ============================================================
# FINAL REPORT
# ============================================================
total = PASS + FAIL
print(f"\n{'='*55}")
print(f"  FINAL REPORT: {PASS}/{total} tests passed")
if FAIL:
    print(f"  {FAIL} test(s) FAILED — review above for details")
else:
    print("  All tests passed. System is working correctly.")
print(f"{'='*55}\n")

sys.exit(0 if FAIL == 0 else 1)
