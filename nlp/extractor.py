import re
from datetime import datetime
from typing import Dict, Any, Optional

class EntityExtractor:
    # Regex patterns
    # Regex patterns
    # Handles: Rs. 100, INR 100, INR Rs. 100, Rs 100, ₹ 100, Amt: 100
    AMOUNT_PATTERN = r'(?i)(?:INR|Rs\.?|₹|Amt:?)\s*([\d,]+(?:\.\d{1,2})?)'
    
    # Common date formats: 14/01/2026, 14-01-26, 14 Jan 2026
    DATE_PATTERN = r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4})'
    
    # Time formats: 8:43 PM, 20:43
    TIME_PATTERN = r'(\d{1,2}:\d{2}(?:\s?[AP]M)?)'

    @staticmethod
    def extract(text: str) -> Dict[str, Any]:
        """
        Extracts key entities from the cleaned text.
        """
        entities = {
            "amount": None,
            "type": None,
            "merchant": None,
            "date": None,
            "time": None,
            "status": None,
            "mode": "UPI" # Defaulting to UPI as per requirement, or we can detect it
        }

        # 1. Extract Amount
        match_amount = re.search(EntityExtractor.AMOUNT_PATTERN, text)
        if match_amount:
            raw_amount = match_amount.group(1).replace(',', '')
            try:
                entities['amount'] = float(raw_amount)
            except ValueError:
                pass

        # 2. Extract Date & Time
        match_date = re.search(EntityExtractor.DATE_PATTERN, text)
        if match_date:
            entities['date'] = match_date.group(1)
        
        match_time = re.search(EntityExtractor.TIME_PATTERN, text)
        if match_time:
            entities['time'] = match_time.group(1)

        # 3. Determine Transaction Type (Credit/Debit)
        text_lower = text.lower()
        
        # Priority 1: Check for explicit Credit indicators that override generic debit words
        if any(w in text_lower for w in ['refund', 'reversed', 'credited back', 'return', 'upi credit']):
             entities['type'] = 'credit'
             
        # Priority 2: Check for Debit keywords (prioritize 'debited' over 'credited' when both appear like 'debited...credited to')
        elif any(w in text_lower for w in ['debited', 'debit', 'upi debit', 'paid', 'sent', 'spent', 'withdrawn', 'transfer']):
            entities['type'] = 'debit'
            
        # Priority 3: Check for Credit keywords (including label-style like "UPI Credit:" or "Credit:")
        elif any(w in text_lower for w in ['credited', 'credit', 'received', 'added', 'deposited']):
            entities['type'] = 'credit'
        
        # 4. Determine Status
        if any(w in text_lower for w in ['failed', 'declined', 'unsuccessful']):
            entities['status'] = 'failed'
        else:
            entities['status'] = 'success'

        # 5. Determine Merchant
        merchant_match = None
        
        # Pattern A: "paid to X", "sent to X"
        if entities['type'] == 'debit':
            match = re.search(r'(?i)\b(?:to|paid to|sent to)\s+([^,.]+?)(?:\s+(?:on|at|via|using|ref|fees|failed|due)|$)', text)
            if match:
                merchant_match = match.group(1)
                
        # Pattern B: "received from X"
        elif entities['type'] == 'credit':
            match = re.search(r'(?i)\b(?:from|received from)\s+([^,.]+?)(?:\s+(?:on|at|via|using|ref)|$)', text)
            if match:
                merchant_match = match.group(1)

        # Pattern C: Info:UPI/REF/MERCHANT (Specific to South Indian Bank & others)
        if not merchant_match:
            match = re.search(r'(?i)info:upi/[^/]+/[^/]+/([^/ ]+)', text)
            if match:
                merchant_match = match.group(1)

        if merchant_match:
            entities['merchant'] = re.sub(r'\s+', ' ', merchant_match).strip()

        return entities
