from .cleaner import TextCleaner
from .intent import IntentDetector
from .extractor import EntityExtractor
from .sender_validator import SenderValidator
import json
from typing import Optional, Dict, Any


class UPIAgent:
    def __init__(self):
        self.sender_validator = SenderValidator()

    def process_message(
        self,
        raw_text: str,
        sender_id: str = None
    ) -> Optional[Dict[str, Any]]:
        """
        Main NLP pipeline:
        1. Clean Text
        2. Check Intent (Transaction vs Spam/OTP)
        3. Validate Sender ID (Lenient: allow unknown senders if intent is valid)
        4. Extract Entities
        5. Attach sender info + confidence score
        """
        # ── Step 1: Clean Text ────────────────────────────────────
        cleaned_text = TextCleaner.clean(raw_text)

        # ── Step 2: Intent Detection ─────────────────────────────
        # We check intent EARLY. If it's not a transaction, we stop immediately.
        if not IntentDetector.is_transaction(cleaned_text):
            return None

        # ── Step 3: Sender ID Validation (Lenient) ────────────────
        sender_info = None
        if sender_id is not None:
            sender_info = self.sender_validator.validate(sender_id)
            
            # If sender is invalid but we already know it's a transaction intent,
            # we DON'T reject. We just treat it as an unverified sender.
            if not sender_info['is_valid']:
                print(f"[UPIAgent] WARNING: Unverified sender '{sender_id}'. Proceeding because intent is valid.")
                # We'll use the provided sender_id but keep bank_name as None
                sender_info['bank_name'] = None
                sender_info['is_valid'] = True # Mark as "valid enough to proceed"

        # ── Step 4: Entity Extraction ─────────────────────────────
        entities = EntityExtractor.extract(cleaned_text)

        # ── Step 5: Attach sender metadata ───────────────────────
        if sender_info:
            entities['sender_id'] = sender_info['sender_id']
            entities['bank_name'] = sender_info['bank_name']
        else:
            entities['sender_id'] = None
            entities['bank_name'] = None

        # ── Step 5: Confidence score ─────────────────────────────
        entities['confidence_score'] = self._calculate_confidence(entities)

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
    print(json.dumps(agent.process_message(sample, sender_id="VM-SBIUPI"), indent=2))
