from src.nlp_agent import UPIAgent
import json

def main():
    agent = UPIAgent()
    
    samples = [
        "₹1,250 debited from your account via UPI to Swiggy on 14/01/2026 at 8:43 PM.",
        "Credited with Rs 5,000 from Salary. Ref 12345",
        "Your OTP for login is 998877",
        "Paid Rs 150 to Zomato via UPI"
    ]
    
    print("--- Running on Samples ---")
    for sample in samples:
        print(f"\nInput: {sample}")
        result = agent.process_message(sample)
        if result:
            print("Output:", json.dumps(result, indent=2))
        else:
            print("Output: [Ignored]")

    print("\n--- Manual Input Mode ---")
    print("Type your SMS message below (or type 'exit' to quit):")
    while True:
        user_input = input("\n> ")
        if user_input.lower() in ['exit', 'quit']:
            break
        
        result = agent.process_message(user_input)
        if result:
            print("Output:", json.dumps(result, indent=2))
        else:
            print("Output: [Ignored] (Not a valid transaction or contains ignore keywords)")

if __name__ == "__main__":
    main()
