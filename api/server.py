"""
api/server.py
-------------
Lightweight FastAPI server that bridges the Flutter app with the Python ML/NLP pipeline.

Endpoints:
    GET  /health          - Health check / ping
    POST /analyze-sms     - Validate sender, parse SMS, predict UPI failure
    POST /budget          - Compute budget summary from transaction list

Start with:
    python api/start_server.py
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import uvicorn

from nlp.nlp_agent import UPIAgent
from ml.ml_agent import MLAgent

# ── App setup ─────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Smart UPI Monitor API",
    description="ML/NLP backend for FinSight Flutter app",
    version="1.0.0",
)

# Allow requests from the Flutter app (Android emulator uses 10.0.2.2)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Shared ML/NLP instances (initialized at startup) ─────────────────────────
nlp_agent: UPIAgent = None
ml_agent:  MLAgent  = None


@app.on_event("startup")
async def startup():
    """Train ML model once on server start."""
    global nlp_agent, ml_agent
    print("[Server] Initializing NLP agent...")
    nlp_agent = UPIAgent()

    print("[Server] Training ML model (5000 synthetic records)...")
    ml_agent = MLAgent(monthly_budget=15000.0)
    ml_agent.train(n_records=5000)
    print("[Server] Ready to serve requests.")


# ── Request/Response models ────────────────────────────────────────────────────

class SMSRequest(BaseModel):
    sender_id: Optional[str] = None   # e.g. "VM-SBIUPI"
    sms_body:  str                    # raw SMS text


class TransactionItem(BaseModel):
    amount:   float
    category: str = "Others"
    status:   str = "Success"         # "Success" | "Failure"


class BudgetRequest(BaseModel):
    transactions:   List[TransactionItem]
    monthly_budget: float = 15000.0


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    """Ping endpoint — Flutter uses this to check if server is alive."""
    return {
        "status": "ok",
        "ml_trained": ml_agent._trained if ml_agent else False,
    }


@app.post("/analyze-sms")
def analyze_sms(req: SMSRequest):
    """
    Full pipeline: sender validation → NLP → ML failure prediction.

    Returns extracted transaction data + ML failure probability + alert.
    If sender is invalid or message is not a transaction, returns rejected=True.
    """
    # Step 1: NLP (handles sender validation internally)
    nlp_result = nlp_agent.process_message(req.sms_body, sender_id=req.sender_id)

    if nlp_result is None:
        return {
            "rejected":   True,
            "reason":     "Invalid sender ID or not a UPI transaction message.",
            "nlp":        None,
            "ml":         None,
        }

    # Step 2: ML prediction via NLP bridge
    ml_result = ml_agent.predict_from_nlp_output(
        nlp_result,
        bank_name      = nlp_result.get("bank_name") or "Unknown",
        network_status = "Good",
        server_status  = "Normal",
        user_id        = "FLUTTER_USER",
    )

    # Build clean response
    alert = ml_result["transaction_alert"] if ml_result else None

    return {
        "rejected": False,
        "nlp": {
            "amount":       nlp_result.get("amount"),
            "type":         nlp_result.get("type"),
            "merchant":     nlp_result.get("merchant"),
            "date":         nlp_result.get("date"),
            "status":       nlp_result.get("status"),
            "bank_name":    nlp_result.get("bank_name"),
            "sender_id":    nlp_result.get("sender_id"),
            "confidence":   nlp_result.get("confidence_score"),
        },
        "ml": {
            "failure_probability":          ml_result["ml_failure_probability"] if ml_result else None,
            "combined_failure_probability": ml_result["combined_failure_probability"] if ml_result else None,
            "alert_level":                  alert["level"] if alert else "LOW",
            "alert_message":                alert["message"] if alert else "Transaction looks safe.",
        } if ml_result else None,
    }


@app.post("/budget")
def budget_summary(req: BudgetRequest):
    """
    Compute budget summary from a list of transactions.
    Returns daily/monthly spend, category breakdown, and budget alert.
    """
    from datetime import datetime
    from ml.budget_insights import BudgetInsights
    from ml.alert_engine import generate_budget_alert

    insights = BudgetInsights(monthly_budget=req.monthly_budget)

    for item in req.transactions:
        insights.add_transaction({
            "amount":             item.amount,
            "transaction_time":   datetime.now(),
            "category":           item.category,
            "transaction_status": item.status,
            "user_id":            "FLUTTER_USER",
        })

    summary = insights.get_summary(user_id="FLUTTER_USER")
    alert   = generate_budget_alert(summary)

    return {
        "budget_summary": summary,
        "budget_alert":   alert,
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
