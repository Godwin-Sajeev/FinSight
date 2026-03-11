class IntentDetector:
    # Keywords that strongly suggest a transaction
    TRANSACTION_KEYWORDS = {
        'debited', 'credited', 'paid', 'sent', 'received', 'spent', 'transferred', 'withdrawn', 'payment', 'txn', 'upi', 'transaction', 'debit', 'credit', 'transfer', 'recharged', 'purchased', 'avl bal'
    }

    # Keywords that suggest non-transactional messages
    IGNORE_KEYWORDS = {
        'otp', 'login', 'code is', 'verification', 'offer', 'reward', 'win', 'loan', 'expire'
    }

    @classmethod
    def is_transaction(cls, text: str) -> bool:
        """
        Determines if the message is a financial transaction.
        """
        if not text:
            return False
            
        text_lower = text.lower()

        # Check for ignore keywords first (False negatives prevention)
        # However, some transaction messages might have "balance" (bal) at the end. 
        # We should be careful. 'bal' is risky if it's "your bal is low".
        # Let's refine ignore list. 
        # A message "OTP 1234 for payment" is an OTP, not a transaction record.
        
        for word in cls.IGNORE_KEYWORDS:
            if word in text_lower:
                # Special case: 'balance' might appear in a valid transaction msg (e.g. "Avail Bal: ...")
                # But 'otp' is definitely not a transaction record.
                return False

        # Check for transaction keywords
        has_keyword = any(keyword in text_lower for keyword in cls.TRANSACTION_KEYWORDS)
        
        return has_keyword
