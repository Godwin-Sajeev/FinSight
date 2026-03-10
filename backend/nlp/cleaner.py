import re

class TextCleaner:
    @staticmethod
    def clean(text: str) -> str:
        """
        Cleans and normalizes the input SMS text.
        """
        if not text:
            return ""

        # 1. Normalize currency (₹, Rs, Rs. -> INR)
        # Handle variations like 'Rs.', 'rs', 'INR', '₹'
        text = re.sub(r'(?i)(₹|Rs\.?|INR)\s*(\d)', r'INR \2', text)
        
        # 2. Remove multiple spaces
        text = re.sub(r'\s+', ' ', text).strip()
        
        # 3. Optional: normalization of common date separators if inconsistent
        # (For now, we trust the regex in extractor to handle date formats, 
        # but we could standardize delimiters here)
        
        return text
