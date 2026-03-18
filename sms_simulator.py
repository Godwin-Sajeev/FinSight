"""
sms_simulator.py
----------------
Terminal-based SMS simulator for testing the NLP + ML pipeline.

Designed for use with Android Studio virtual phone — you type in
a sender ID and SMS body, and the system processes it through the
full pipeline (sender validation → NLP → ML prediction).

Usage:
    python sms_simulator.py                  # Interactive mode
    python sms_simulator.py --quick          # Run preset demo messages
"""

import json
import sys
import os

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from nlp.nlp_agent import UPIAgent
from nlp.sender_validator import SenderValidator


# ── Preset demo messages (for --quick mode) ──────────────────────
DEMO_MESSAGES = [
    {
        'sender_id': 'VM-SBIUPI',
        'message':   '₹1,250 debited from your account via UPI to Swiggy on 14/01/2026 at 8:43 PM. Ref ID 98374628',
        'desc':      '[OK] Valid SBI debit SMS',
    },
    {
        'sender_id': 'JD-IPBMSG-S',
        'message':   'A/C X4952 Debit Rs.100.00 for UPI to Generic User on 12-01-26 Ref 601202411884. Avl Bal Rs.669.76-IPPB',
        'desc':      '[OK] Valid IPPB debit SMS',
    },
    {
        'sender_id': 'VK-ICICIB',
        'message':   'Your account is credited with Rs 500.00 from John Doe on 15-01-26.',
        'desc':      '[OK] Valid ICICI credit SMS',
    },
    {
        'sender_id': 'XX-SPAM01',
        'message':   'Congratulations! You won INR 50,000. Click here to claim your prize.',
        'desc':      '[SPAM] Invalid sender ID',
    },
    {
        'sender_id': 'AM-HDFCBK',
        'message':   'Your OTP is 123456. Do not share this code.',
        'desc':      '[NOTE] Valid sender but NOT a transaction (OTP)',
    },
    {
        'sender_id': 'BP-AXISBK',
        'message':   'Transaction of INR 200 to Uber failed due to insufficient funds.',
        'desc':      '[OK] Valid Axis -- failed transaction detected',
    },
]

SEPARATOR = "─" * 60


def print_banner():
    print()
    print("=" * 56)
    print("   SMS SIMULATOR -- UPI Transaction Monitor")
    print("   Fake SMS input for Android Studio virtual phone")
    print("=" * 56)
    print()


def print_sender_list():
    """Print known valid sender IDs for reference."""
    validator = SenderValidator()
    print("  Valid Bank Sender IDs:")
    print("  " + "─" * 40)

    # Group by bank
    bank_senders = {}
    for sid, bank in validator.registry.items():
        bank_senders.setdefault(bank, []).append(sid)

    for bank, senders in sorted(bank_senders.items()):
        senders_str = ", ".join(senders)
        print(f"    {bank:<25} → {senders_str}")
    print("  " + "─" * 40)
    print()


def process_and_display(agent: UPIAgent, sender_id: str, message: str, label: str = ""):
    """Process a single SMS and display results."""
    if label:
        print(f"\n  {label}")
    print(f"  Sender : {sender_id}")
    print(f"  Message: {message[:80]}{'...' if len(message) > 80 else ''}")
    print(f"  {SEPARATOR}")

    result = agent.process_message(message, sender_id=sender_id)

    if result is None:
        print("  REJECTED -- message was filtered out (invalid sender or not a transaction)")
    else:
        print("  ACCEPTED -- extracted data:")
        # Pretty-print with indent
        for key, value in result.items():
            print(f"     {key:<20}: {value}")

    print(f"  {SEPARATOR}\n")
    return result


def run_quick_demo(agent: UPIAgent):
    """Run all preset demo messages."""
    print_banner()
    print("  QUICK DEMO MODE -- running preset messages\n")

    accepted = 0
    rejected = 0

    for i, demo in enumerate(DEMO_MESSAGES, 1):
        print(f"  ── Message {i}/{len(DEMO_MESSAGES)} ──")
        result = process_and_display(
            agent,
            demo['sender_id'],
            demo['message'],
            label=demo['desc']
        )
        if result:
            accepted += 1
        else:
            rejected += 1

    print(f"\n  Summary: {accepted} accepted, {rejected} rejected out of {len(DEMO_MESSAGES)} messages")
    print()


def run_interactive(agent: UPIAgent):
    """Interactive mode: user types sender ID + message."""
    print_banner()
    print_sender_list()

    print("  Type 'quit' to exit. Type 'list' to show valid sender IDs.\n")

    while True:
        try:
            # Get sender ID
            sender_id = input("  Sender ID (e.g. VM-SBIUPI): ").strip()

            if sender_id.lower() in ('quit', 'exit', 'q'):
                print("\n  Goodbye!\n")
                break

            if sender_id.lower() == 'list':
                print_sender_list()
                continue

            if not sender_id:
                print("  WARNING: Sender ID cannot be empty. Try again.\n")
                continue

            # Get message body
            message = input("  SMS Body: ").strip()

            if not message:
                print("  WARNING: Message cannot be empty. Try again.\n")
                continue

            # Process
            process_and_display(agent, sender_id, message)

        except (KeyboardInterrupt, EOFError):
            print("\n\n  Goodbye!\n")
            break


def main():
    agent = UPIAgent()

    if '--quick' in sys.argv or '--demo' in sys.argv:
        run_quick_demo(agent)
    else:
        run_interactive(agent)


if __name__ == "__main__":
    main()
