from .cleaner import TextCleaner
from .intent import IntentDetector
from .extractor import EntityExtractor
import json
from typing import Optional, Dict, Any

class UPIAgent:
    def __init__(self):
        pass

    def process_message(self, raw_text: str) -> Optional[Dict[str, Any]]:
        """
        Main pipeline:
        1. Clean Text
        2. Check Intent
        3. Extract Entities
        4. Structure Output
        """
        # 1. Clean
        cleaned_text = TextCleaner.clean(raw_text)
        
        # 2. Intent
        if not IntentDetector.is_transaction(cleaned_text):
            # Not a transaction
            return None
        
        # 3. Extract
        entities = EntityExtractor.extract(cleaned_text)
        
        # 4. Post-process / Formatting (Example: standardize date format if needed)
        # For now, we return the entities as extracted.
        
        # Add metadata or confidence (Mock implementation for confidence)
        confidence = self._calculate_confidence(entities)
        entities['confidence_score'] = confidence
        
        return entities

    def _calculate_confidence(self, entities: Dict[str, Any]) -> float:
        """
        Simple confidence scoring based on presence of key fields.
        """
        required_fields = ['amount', 'type', 'merchant']
        present = sum(1 for f in required_fields if entities.get(f))
        score = present / len(required_fields)
        return round(score, 2)

if __name__ == "__main__":
    # Simple CLI test
    agent = UPIAgent()
    sample = "₹1,250 debited from your account via UPI to Swiggy on 14/01/2026 at 8:43 PM. Ref ID 98374628"
    print(json.dumps(agent.process_message(sample), indent=2))
