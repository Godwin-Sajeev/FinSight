"""
api/test_api.py
---------------
Quick test script to verify all API endpoints work correctly.
Run AFTER starting the server with: python api/start_server.py

Usage:
    python api/test_api.py
"""

import sys
import json

try:
    import requests
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "-q"])
    import requests

BASE = "http://localhost:8001"
PASS = 0
FAIL = 0

def check(label, condition, info=""):
    global PASS, FAIL
    if condition:
        print(f"  [PASS] {label}")
        PASS += 1
    else:
        print(f"  [FAIL] {label}  -> {info}")
        FAIL += 1

def section(title):
    print(f"\n{'='*50}\n  {title}\n{'='*50}")

# ── 1. Health check    
section("1. Health Check")
r = requests.get(f"{BASE}/health", timeout=5)
check("Server responds 200",  r.status_code == 200)
check("ML model is trained",  r.json().get("ml_trained") == True, r.json())

# ── 2. Valid SMS - SBI debit   
section("2. Valid SBI Debit SMS")
r = requests.post(f"{BASE}/analyze-sms", json={
    "sender_id": "VM-SBIUPI",
    "sms_body":  "Rs.1250 debited from your account via UPI to Swiggy on 14/01/2026 at 8:43 PM.",
}, timeout=10)
data = r.json()
check("Status 200",               r.status_code == 200)
check("Not rejected",             not data.get("rejected"))
check("Amount parsed = 1250",     data.get("nlp", {}).get("amount") == 1250.0, data.get("nlp"))
check("Bank = SBI",               data.get("nlp", {}).get("bank_name") == "SBI")
check("ML result present",        data.get("ml") is not None)
check("Alert level present",      data.get("ml", {}).get("alert_level") in ("LOW","MEDIUM","HIGH"))

# ── 3. Valid IPPB SMS  
section("3. Valid IPPB SMS (JD-IPBMSG-S)")
r = requests.post(f"{BASE}/analyze-sms", json={
    "sender_id": "JD-IPBMSG-S",
    "sms_body":  "A/C X4952 Debit Rs.100.00 for UPI to Generic User on 12-01-26 Ref 601-IPPB",
}, timeout=10)
data = r.json()
check("Not rejected",      not data.get("rejected"))
check("Amount = 100.0",    data.get("nlp", {}).get("amount") == 100.0)
check("Bank = IPPB",       data.get("nlp", {}).get("bank_name") == "IPPB")

# ── 4. Spam sender rejected    
section("4. Spam/Fake Sender Rejection")
r = requests.post(f"{BASE}/analyze-sms", json={
    "sender_id": "XX-SPAM01",
    "sms_body":  "Rs.50000 won! Click here to claim your UPI prize.",
}, timeout=10)
data = r.json()
check("Rejected = True",    data.get("rejected") == True)
check("ML = None",          data.get("ml") is None)

# ── 5. OTP filtered         
section("5. OTP Message Filtered")
r = requests.post(f"{BASE}/analyze-sms", json={
    "sender_id": "AM-HDFCBK",
    "sms_body":  "Your OTP is 123456. Do not share with anyone.",
}, timeout=10)
data = r.json()
check("Rejected (OTP not a transaction)", data.get("rejected") == True)

# ── 6. Budget summary  
section("6. Budget Summary Endpoint")
r = requests.post(f"{BASE}/budget", json={
    "monthly_budget": 10000.0,
    "transactions": [
        {"amount": 500.0,  "category": "Food",     "status": "Success"},
        {"amount": 1200.0, "category": "Bills",    "status": "Success"},
        {"amount": 300.0,  "category": "Travel",   "status": "Success"},
        {"amount": 8500.0, "category": "Shopping", "status": "Success"},
    ],
}, timeout=10)
data = r.json()
check("Status 200",                r.status_code == 200)
check("Budget summary present",    "budget_summary" in data)
check("Monthly spend = 10500",     data.get("budget_summary", {}).get("total_monthly_spend") == 10500.0,
      data.get("budget_summary", {}).get("total_monthly_spend"))
check("Budget alert present",      "budget_alert" in data)
check("Alert level = WARNING",     data.get("budget_alert", {}).get("level") == "WARNING",
      data.get("budget_alert"))

# ── Final report   
total = PASS + FAIL
print(f"\n{'='*50}")
print(f"  RESULT: {PASS}/{total} passed")
if FAIL:
    print(f"  {FAIL} test(s) FAILED")
else:
    print("  All API tests passed. Server is working correctly.")
print(f"{'='*50}\n")

sys.exit(0 if FAIL == 0 else 1)
