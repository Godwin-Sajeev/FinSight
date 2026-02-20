import re
from datetime import datetime
from typing import Dict, Any, Optional

class EntityExtractor:
    # Regex patterns
    AMOUNT_PATTERN = r'(?i)(?:INR|Rs\.?)\s*([\d,]+(?:\.\d{1,2})?)'
    
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
        if any(w in text_lower for w in ['refund', 'reversed', 'credited back', 'return']):
             entities['type'] = 'credit'
             
        # Priority 2: Check for Debit keywords (prioritize 'debited' over 'credited' when both appear like 'debited...credited to')
        elif any(w in text_lower for w in ['debited', 'paid', 'sent', 'spent', 'withdrawn', 'transfer']):
            entities['type'] = 'debit'
            
        # Priority 3: Check for Credit keywords
        elif any(w in text_lower for w in ['credited', 'received', 'added', 'deposited']):
            entities['type'] = 'credit'
        
        # 4. Determine Status
        if any(w in text_lower for w in ['failed', 'declined', 'unsuccessful']):
            entities['status'] = 'failed'
        else:
            # Default to success if it looks like a transaction and isn't failed
            # This is a strong assumption, but standard for completed txn SMS
            entities['status'] = 'success'

        # 5. Determine Type & Merchant (Iterative Refinement)
        
        # Heuristic: infer type from prepositions if not explicitly found
        if entities['type'] is None:
            if re.search(r'\bto\s+', text_lower):
                entities['type'] = 'debit'
            elif re.search(r'\bfrom\s+', text_lower):
                 entities['type'] = 'credit'

        merchant_match = None
        if entities['type'] == 'debit':
            # "paid to X", "sent to X", "to X"
            # Try to grab text between 'to' and next keyword or end
            match = re.search(r'(?i)\bto\s+([^,.]+?)(?:\s+(?:on|at|via|using|ref|fees|failed|due)|$)', text)
            if match:
                # Remove extra spaces if captured
                merchant_match = re.sub(r'\s+', ' ', match.group(1)).strip()
        elif entities['type'] == 'credit':
             # "received from X", "from X"
            match = re.search(r'(?i)\bfrom\s+([^,.]+?)(?:\s+(?:on|at|via|using|ref)|$)', text)
            if match:
                merchant_match = match.group(1)
        
        if merchant_match:
            entities['merchant'] = merchant_match.strip()

        return entities
