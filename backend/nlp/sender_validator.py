"""
sender_validator.py
-------------------
Validates SMS sender IDs against a registry of known Indian bank sender IDs.
Rejects spam/fake messages by ensuring the sender matches a verified bank.

Usage:
    validator = SenderValidator()
    result = validator.validate("VM-SBIUPI")
    # {'is_valid': True, 'bank_name': 'SBI', 'sender_id': 'VM-SBIUPI'}
"""

import re
from typing import Dict, Any, Optional


# Registry of verified bank sender IDs
# Format: sender_id (uppercase) -> bank_name
VALID_SENDER_IDS: Dict[str, str] = {
    # --- SBI ---
    'VM-SBIUPI':    'SBI',
    'VM-SBIPSG':    'SBI',
    'VD-SBIINB':    'SBI',

    # --- ICICI ---
    'VK-ICICIB':    'ICICI',
    'VM-ICICIB':    'ICICI',

    # --- HDFC ---
    'AM-HDFCBK':    'HDFC',
    'VM-HDFCBK':    'HDFC',

    # --- Axis ---
    'BP-AXISBK':    'Axis',
    'VM-AXISBK':    'Axis',

    # --- Kotak ---
    'JD-KOTAKB':    'Kotak',
    'VM-KOTAKB':    'Kotak',

    # --- PNB ---
    'AX-PNBSMS':   'PNB',
    'VM-PNBSMS':   'PNB',

    # --- BOB (Bank of Baroda) ---
    'BW-BOBSMS':   'BOB',
    'VM-BOBTXN':   'BOB',

    # --- IPPB (India Post Payments Bank) ---
    'VM-IPPBKN':   'IPPB',
    'JD-IPBMSG':   'IPPB',
    'JD-IPBMSG-S': 'IPPB',

    # --- South Indian Bank ---
    'AX-SIBSMS':   'South Indian Bank',

    # --- Federal Bank ---
    'AD-FEDBNK':   'Federal Bank',
    'VM-FEDBNK':   'Federal Bank',

    # --- Paytm Payments Bank ---
    'JD-PAYTMB':   'Paytm Payments Bank',
    'VM-PAYTMB':   'Paytm Payments Bank',

    # --- Airtel Payments Bank ---
    'BZ-ABORIG':   'Airtel Payments Bank',

    # --- Kerala Gramin Bank ---
    'VM-KGBANK':   'Kerala Gramin Bank',

    # --- Union Bank ---
    'VM-UBIONL':   'Union Bank',

    # --- Canara Bank ---
    'VM-CANBNK':   'Canara Bank',

    # --- Indian Bank ---
    'VM-INDBNK':   'Indian Bank',
}


class SenderValidator:
    """
    Validates SMS sender IDs against the known bank registry.
    """

    def __init__(self, extra_senders: Optional[Dict[str, str]] = None):
        """
        Parameters:
            extra_senders: Additional sender_id -> bank_name mappings
                           to extend the default registry.
        """
        self.registry: Dict[str, str] = {k.upper(): v for k, v in VALID_SENDER_IDS.items()}
        if extra_senders:
            for sid, bank in extra_senders.items():
                self.registry[sid.upper()] = bank

    def validate(self, sender_id: str) -> Dict[str, Any]:
        """
        Check if a sender ID belongs to a verified bank.

        Parameters:
            sender_id (str): The SMS sender ID, e.g. 'VM-SBIUPI'

        Returns:
            dict: {
                'is_valid':   bool,
                'bank_name':  str or None,
                'sender_id':  str (normalized to uppercase),
                'reason':     str (why it was rejected, if invalid)
            }
        """
        if not sender_id or not sender_id.strip():
            return {
                'is_valid':  False,
                'bank_name': None,
                'sender_id': sender_id,
                'reason':    'Empty sender ID',
            }

        normalized = sender_id.strip().upper()

        # --- Exact match ---
        if normalized in self.registry:
            return {
                'is_valid':  True,
                'bank_name': self.registry[normalized],
                'sender_id': normalized,
                'reason':    None,
            }

        # --- Partial match: strip the 2-char prefix (e.g. VM-, AX-) ---
        # Some phones show sender IDs without the prefix
        suffix = re.sub(r'^[A-Z]{2}-', '', normalized)
        for reg_id, bank_name in self.registry.items():
            reg_suffix = re.sub(r'^[A-Z]{2}-', '', reg_id)
            if suffix == reg_suffix:
                return {
                    'is_valid':  True,
                    'bank_name': bank_name,
                    'sender_id': normalized,
                    'reason':    None,
                }

        # --- No match: likely spam or unknown sender ---
        return {
            'is_valid':  False,
            'bank_name': None,
            'sender_id': normalized,
            'reason':    f'Sender ID "{normalized}" not found in verified bank registry',
        }
