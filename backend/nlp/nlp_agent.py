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
        0. Validate Sender ID  (NEW — rejects spam/fake senders)
        1. Clean Text
        2. Check Intent
        3. Extract Entities
        4. Attach sender info + confidence score

        Parameters:
            raw_text  (str):  The raw SMS body text.
            sender_id (str):  SMS sender ID, e.g. 'VM-SBIUPI', 'JD-IPBMSG-S'.
                              If None, sender validation is skipped (backward compatible).

        Returns:
            dict with extracted entities + sender info, or None if rejected.
        """
        # ── Step 0: Sender ID Validation ──────────────────────────
        sender_info = None
        if sender_id is not None:
            sender_info = self.sender_validator.validate(sender_id)
            if not sender_info['is_valid']:
                # Reject: not from a verified bank
                print(f"[UPIAgent] ❌ Rejected — {sender_info['reason']}")
                return None

        # ── Step 1: Clean Text ────────────────────────────────────
        cleaned_text = TextCleaner.clean(raw_text)

        # ── Step 2: Intent Detection ─────────────────────────────
        if not IntentDetector.is_transaction(cleaned_text):
            return None

        # ── Step 3: Entity Extraction ─────────────────────────────
        entities = EntityExtractor.extract(cleaned_text)

        # ── Step 4: Attach sender metadata ───────────────────────
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
