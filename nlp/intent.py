import re

class IntentDetector:
    # Keywords that strongly suggest a transaction
    TRANSACTION_KEYWORDS = {
        'debited', 'credited', 'paid', 'sent', 'received', 'spent', 'transferred', 'withdrawn', 'payment', 'txn', 'upi', 'transaction', 'debit', 'credit', 'transfer', 'recharged', 'purchased', 'avl bal', 'deposited'
    }

    # Keywords that suggest non-transactional messages
    IGNORE_KEYWORDS = {
        'otp', 'login', 'code is', 'verification', 'offer', 'reward', 'win', 'won', 'prize', 'loan', 'expire'
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
        for word in cls.IGNORE_KEYWORDS:
            if re.search(rf'\b{re.escape(word)}\b', text_lower):
                return False

        # Check for transaction keywords
        for keyword in cls.TRANSACTION_KEYWORDS:
            if re.search(rf'\b{re.escape(keyword)}\b', text_lower) or keyword in text_lower if ' ' in keyword else False:
                return True
                
        # Handle spaced keywords (like 'avl bal') and pure substrings if needed 
        # (above regex handles space well enough but fallback is good)
        has_keyword = any(keyword in text_lower for keyword in cls.TRANSACTION_KEYWORDS)
        
        return has_keyword
