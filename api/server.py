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
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv
import uuid

# Add project root to path for local imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import uvicorn
import random
import time
from datetime import datetime, timedelta

from nlp.nlp_agent import UPIAgent
from ml.ml_agent import MLAgent

# Load environment variables
load_dotenv()
EMAIL_USER = os.getenv("EMAIL_USER")
EMAIL_PASS = os.getenv("EMAIL_PASS")

# ── Logging Setup ───────────────────────────────────────────
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("FinSight-Server")

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


class OTPRequest(BaseModel):
    email: str


class VerifyRequest(BaseModel):
    email: str
    otp:   str


# ── In-memory OTP store (Email -> {otp, expires_at}) ─────────────────────────
otp_store = {}


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


@app.post("/auth/send-otp")
async def send_otp(req: OTPRequest):
    """Generates a 6-digit OTP and sends it via email."""
    logger.info(f"Received OTP request for: {req.email}")
    otp = f"{random.randint(100000, 999999)}"
    expires_at = datetime.now() + timedelta(minutes=5)
    
    otp_store[req.email] = {
        "otp": otp,
        "expires_at": expires_at
    }
    
    # ── Real Email Logic (smtplib) ──────────────────────────────
    if not EMAIL_USER or not EMAIL_PASS:
        logger.warning("SMTP credentials not set. Falling back to console print.")
        print(f"\n[AUTH] ********* REAL EMAIL OTP *********")
        print(f"[AUTH] TO: {req.email}")
        print(f"[AUTH] CODE: {otp}")
        print(f"[AUTH] **********************************\n")
        return {"success": True, "message": "OTP printed to server console (SMTP not set)"}

    try:
        msg = MIMEMultipart('alternative')
        msg['From'] = f"FinSight Security <{EMAIL_USER}>"
        msg['To'] = req.email
        msg['Subject'] = f"{otp} is your FinSight verification code"
        
        # Plain text fallback
        text = f"Your FinSight verification code is: {otp}\nExpires in 5 minutes."
        
        # Professional HTML Template
        html = f"""
        <html>
        <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f9f9fb; padding: 40px; color: #1a1a1a;">
            <div style="max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
                <div style="background: #6366f1; padding: 30px; text-align: center;">
                    <h1 style="color: #ffffff; margin: 0; font-size: 28px;">FinSight</h1>
                </div>
                <div style="padding: 40px; text-align: center;">
                    <h2 style="color: #333; margin-bottom: 8px;">Verification Code</h2>
                    <p style="color: #666; font-size: 16px; margin-bottom: 30px;">Input the code below to securely sign in to your account.</p>
                    <div style="background: #f3f4f6; padding: 20px; border-radius: 12px; display: inline-block;">
                        <span style="font-size: 36px; font-weight: 800; letter-spacing: 6px; color: #6366f1;">{otp}</span>
                    </div>
                    <p style="color: #999; font-size: 13px; margin-top: 30px;">This code will expire in <b>5 minutes</b>.<br>If you didn't request this code, please ignore this email.</p>
                </div>
                <div style="background: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #eee;">
                    <p style="color: #aaa; font-size: 11px; margin: 0;">© 2026 FinSight. Secure Smart Budgeting.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(text, 'plain'))
        msg.attach(MIMEText(html, 'html'))
        
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(EMAIL_USER, EMAIL_PASS)
        server.send_message(msg)
        server.quit()
        
        logger.info(f"OTP sent successfully to {req.email}")
        return {"success": True, "message": "OTP sent"}
    except Exception as e:
        logger.error(f"Failed to send email: {e}")
        return {"success": False, "message": f"Failed to send email: {str(e)}"}


@app.post("/auth/verify-otp")
async def verify_otp(req: VerifyRequest):
    """Verifies the 6-digit OTP for the given email."""
    if req.email not in otp_store:
        return {"success": False, "message": "No OTP requested for this email."}
    
    stored = otp_store[req.email]
    
    if datetime.now() > stored["expires_at"]:
        del otp_store[req.email]
        return {"success": False, "message": "Invalid or expired OTP"}
    
    if stored["otp"] == req.otp:
        del otp_store[req.email] # Consume OTP
        token = str(uuid.uuid4()) # Generate a dummy session token
        return {"success": True, "token": token}
    
    return {"success": False, "message": "Invalid or expired OTP"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
