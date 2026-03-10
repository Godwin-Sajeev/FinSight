from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from ml.ml_agent import MLAgent
from nlp.nlp_agent import UPIAgent

app = FastAPI(title="FinSight API", description="Backend API for FinSight Flutter App")

# Initialize models
ml_agent = MLAgent(monthly_budget=15000.0)
nlp_agent = UPIAgent()

# Note: In a real app we'd load a saved model, but for this demo 
# we'll train on startup so the predict endpoints work
@app.on_event("startup")
async def startup_event():
    print("Training ML model on synthetic data...")
    ml_agent.train(n_records=2000)
    print("ML model training complete.")

class SMSRequest(BaseModel):
    message: str
    sender_id: str | None = None
    user_id: str = "USER_DEFAULT"

@app.get("/")
def read_root():
    return {"status": "ok", "message": "FinSight API is running"}

@app.post("/api/v1/process_sms")
def process_sms(request: SMSRequest):
    # 1. Process with NLP Agent
    nlp_result = nlp_agent.process_message(
        raw_text=request.message, 
        sender_id=request.sender_id
    )
    
    if nlp_result is None:
        raise HTTPException(status_code=400, detail="Could not extract valid transaction data from SMS")
        
    # 2. Process with ML Agent
    ml_result = ml_agent.predict_from_nlp_output(
        nlp_output=nlp_result,
        bank_name=nlp_result.get('bank_name', 'Unknown'),
        user_id=request.user_id
    )
    
    if ml_result is None:
        raise HTTPException(status_code=400, detail="ML Model failed to process NLP output")
        
    return {
        "nlp_extraction": nlp_result,
        "ml_analysis": ml_result
    }
