import sys
import os
import logging
import smtplib
import random
import uuid
import threading
from datetime import datetime, timedelta
from typing import Optional, List
from contextlib import asynccontextmanager

from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv
from fastapi import FastAPI, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Add project root to path for local imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from nlp.nlp_agent import UPIAgent
from ml.ml_agent import MLAgent

# Load environment variables
load_dotenv()
EMAIL_USER = os.getenv("EMAIL_USER")
EMAIL_PASS = os.getenv("EMAIL_PASS")

# ── Logging Setup ───────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("FinSight-Server")

# ── Shared ML/NLP instances ─────────────────────────
nlp_agent: Optional[UPIAgent] = None
ml_agent:  Optional[MLAgent]  = None
otp_store = {}
last_debug_otp = {"email": None, "otp": None}

def init_agents():
    """Heavy initialization performed in background thread."""
    global nlp_agent, ml_agent
    try:
        logger.info("Starting background initialization...")
        nlp_agent = UPIAgent()
        ml_agent = MLAgent(monthly_budget=15000.0)
        ml_agent.train(n_records=5000)
        logger.info("Background initialization COMPLETE.")
    except Exception as e:
        logger.error(f"Initialization failed: {e}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Modern FastAPI startup/shutdown."""
    # Start training in background so server is ready INSTANTLY
    threading.Thread(target=init_agents, daemon=True).start()
    yield
    # Shutdown logic here if needed

# ── App setup ─────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Smart UPI Monitor API",
    lifespan=lifespan,
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Models ────────────────────────────────────────────────────────────────────
class SMSRequest(BaseModel):
    sender_id: Optional[str] = None
    sms_body:  str

class TransactionItem(BaseModel):
    amount:   float
    category: str = "Others"
    status:   str = "Success"

class BudgetRequest(BaseModel):
    transactions:   List[TransactionItem]
    monthly_budget: float = 15000.0

class OTPRequest(BaseModel):
    email: str

class VerifyRequest(BaseModel):
    email: str
    otp:   str

# ── Email Task ────────────────────────────────────────────────────────────────
def send_email_task(email: str, otp: str):
    """Sends email without blocking. Uses timeout to prevent hanging."""
    if not EMAIL_USER or not EMAIL_PASS:
        logger.warning(f"No SMTP credentials. OTP for {email}: {otp}")
        return

    try:
        msg = MIMEMultipart('alternative')
        msg['From'] = f"FinSight Security <{EMAIL_USER}>"
        msg['To'] = email
        msg['Subject'] = f"{otp} is your FinSight code"
        
        html = f"<h2>Code: {otp}</h2><p>Expires in 5 mins.</p>"
        msg.attach(MIMEText(html, 'html'))
        
        # Dial home to Gmail
        with smtplib.SMTP('smtp.gmail.com', 587, timeout=10) as server:
            server.starttls()
            server.login(EMAIL_USER, EMAIL_PASS)
            server.send_message(msg)
        logger.info(f"Email sent successfully to {email}")
    except Exception as e:
        logger.error(f"Email delivery failed (likely blocked by Cloud provider): {e}")

# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {
        "status": "ok",
        "ml_ready": ml_agent._trained if ml_agent else False,
        "server_time": datetime.now().isoformat()
    }

@app.post("/auth/send-otp")
async def send_otp(req: OTPRequest, background_tasks: BackgroundTasks):
    """Generates OTP and responds INSTANTLY."""
    logger.info(f"OTP Request: {req.email}")
    otp = f"{random.randint(100000, 999999)}"
    
    # Store for verification
    otp_store[req.email] = {
        "otp": otp,
        "expires_at": datetime.now() + timedelta(minutes=5)
    }
    
    # Store for debug endpoint (if email fails)
    global last_debug_otp
    last_debug_otp = {"email": req.email, "otp": otp}
    
    background_tasks.add_task(send_email_task, req.email, otp)
    
    return {"success": True, "message": "OTP task created"}

@app.get("/auth/debug-otp")
def debug_otp():
    """Emergency endpoint: If email is blocked, visit this URL to see your code."""
    return last_debug_otp

@app.post("/auth/verify-otp")
async def verify_otp(req: VerifyRequest):
    if req.email not in otp_store:
        return {"success": False, "message": "No OTP requested"}
    
    stored = otp_store[req.email]
    if datetime.now() > stored["expires_at"]:
        return {"success": False, "message": "OTP expired"}
        
    if stored["otp"] == req.otp:
        del otp_store[req.email]
        return {"success": True, "token": str(uuid.uuid4())}
    
    return {"success": False, "message": "Invalid code"}

@app.post("/analyze-sms")
def analyze_sms(req: SMSRequest):
    if not nlp_agent or not ml_agent:
        return {"rejected": True, "reason": "Server still initializing ML models. Try in 30 seconds."}
    
    nlp_result = nlp_agent.process_message(req.sms_body, sender_id=req.sender_id)
    if not nlp_result:
        return {"rejected": True, "reason": "Not a transaction"}

    ml_result = ml_agent.predict_from_nlp_output(
        nlp_result,
        bank_name=nlp_result.get("bank_name") or "Bank",
        network_status="Good",
        server_status="OK",
        user_id="USER"
    )

    # ── Flatten ML result to match MLData.fromJson in Flutter ────────────────
    alert = ml_result.get("transaction_alert", {})
    ml_flat = {
        "failure_probability":          ml_result.get("ml_failure_probability", 0.0),
        "combined_failure_probability": ml_result.get("combined_failure_probability", 0.0),
        "alert_level":                  alert.get("level", "LOW"),
        "alert_message":                alert.get("message", "Transaction looks safe."),
    }

    # ── Flatten NLP result to match NLPData.fromJson in Flutter ──────────────
    nlp_flat = {
        "amount":      nlp_result.get("amount"),
        "type":        nlp_result.get("type"),
        "merchant":    nlp_result.get("merchant"),
        "date":        nlp_result.get("date"),
        "status":      nlp_result.get("status"),
        "bank_name":   nlp_result.get("bank_name"),
        "sender_id":   nlp_result.get("sender_id"),
        "confidence":  nlp_result.get("confidence_score"),
    }

    return {"rejected": False, "nlp": nlp_flat, "ml": ml_flat}

@app.post("/budget")
def budget_summary(req: BudgetRequest):
    from ml.budget_insights import BudgetInsights
    from ml.alert_engine import generate_budget_alert
    
    insights = BudgetInsights(monthly_budget=req.monthly_budget)
    for item in req.transactions:
        insights.add_transaction({"amount": item.amount, "category": item.category, "transaction_status": item.status, "user_id": "USER"})
    
    summary = insights.get_summary(user_id="USER")
    return {"budget_summary": summary, "budget_alert": generate_budget_alert(summary)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
