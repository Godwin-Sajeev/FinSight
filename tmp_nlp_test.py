import sys
import os

# Add the project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from nlp.nlp_agent import UPIAgent

agent = UPIAgent()

messages = [
    # SBI Debit
    ("SBI", "Dear SBI User, your A/c X1234-debited by Rs1,250.00 on 14Jan26 trf to Swiggy. Ref No 12345678"),
    # HDFC Credit
    ("HDFC", "UPDATE: INR 5000.00 deposited in HDFC Bank A/c xx8901 on 15-01-26 12:45:00. Info: UPI/3015/Godwin."),
    # ICICI Debit
    ("ICICI", "Acct XX123 debited with INR 230.50 on 17-Mar-26. Info: UPI-Zomato-UPI. Available Bal INR 5,432."),
    # Axis Debit
    ("Axis", "Rs.500.00 debited from a/c **4567 on 15-03-26 to VPA amazon@upi. UPI Ref No 567890"),
    # General Credit
    ("Unknown", "Credited Rs. 1000 to your A/c ending 1234 on 17/03. Ref: UPI/123/Raj"),
    # Failing example provided by user
    ("Unknown", "Rs.150 debited from SBI account to Amazon"),
    # Non-transaction
    ("Spam", "Your OTP for login is 123456. Do not share this with anyone.")
]

results = []
for bank, msg in messages:
    res = agent.process_message(msg, sender_id=f"VD-{bank}")
    results.append({
        "bank": bank,
        "message": msg,
        "result": res
    })

with open("nlp_results.json", "w") as f:
    json.dump(results, f, indent=2)

print("Tests complete. Results written to nlp_results.json")
