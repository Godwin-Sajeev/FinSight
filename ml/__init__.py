# ML Engine Package
# Smart UPI Transaction Monitoring: Expense Analysis and Failure Prediction
# ---
# Modules:
#   data_generator  → Synthetic dataset creation
#   preprocessor    → Feature engineering & encoding
#   model           → Random Forest train/predict/evaluate
#   risk_analyzer   → Sliding window high-risk detection
#   alert_engine    → Alert generation
#   budget_insights → Spending analysis
#   ml_agent        → Main orchestrator (integrable with NLP agent)

from .ml_agent import MLAgent
