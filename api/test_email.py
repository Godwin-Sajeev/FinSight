import os
import smtplib
from email.mime.text import MIMEText
from dotenv import load_dotenv

def test_smtp():
    # Load .env from the project root (one level up from /api)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_path = os.path.join(os.path.dirname(script_dir), '.env')
    load_dotenv(dotenv_path=env_path)
    
    user = os.getenv("EMAIL_USER")
    password = os.getenv("EMAIL_PASS")
    
    if not user or "your-email" in user:
        print("❌ Error: EMAIL_USER is not set in .env")
        return
        
    print(f"Testing SMTP for: {user}...")
    
    try:
        msg = MIMEText("This is a test email from FinSight.")
        msg['Subject'] = "FinSight SMTP Test"
        msg['From'] = user
        msg['To'] = user
        
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.set_debuglevel(1)
        server.starttls()
        server.login(user, password)
        server.send_message(msg)
        server.quit()
        print("\n✅ Success! SMTP is working correctly.")
    except Exception as e:
        print(f"\n❌ SMTP Failed: {e}")

if __name__ == "__main__":
    test_smtp()
