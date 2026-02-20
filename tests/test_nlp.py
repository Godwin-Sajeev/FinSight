import unittest
from src.nlp_agent import UPIAgent

class TestUPIAgent(unittest.TestCase):
    def setUp(self):
        self.agent = UPIAgent()

    def test_debit_swiggy(self):
        text = "₹1,250 debited from your account via UPI to Swiggy on 14/01/2026 at 8:43 PM. Ref ID 98374628"
        result = self.agent.process_message(text)
        self.assertIsNotNone(result)
        self.assertEqual(result['amount'], 1250.0)
        self.assertEqual(result['type'], 'debit')
        self.assertEqual(result['merchant'], 'Swiggy')
        self.assertEqual(result['date'], '14/01/2026')
        self.assertEqual(result['status'], 'success')

    def test_credit_simple(self):
        text = "Your account is credited with Rs 500.00 from John Doe on 15-01-26."
        result = self.agent.process_message(text)
        self.assertIsNotNone(result)
        self.assertEqual(result['amount'], 500.0)
        self.assertEqual(result['type'], 'credit')
        self.assertEqual(result['merchant'], 'John Doe')
    
    def test_ignore_otp(self):
        text = "Your OTP is 123456. Do not share this code."
        result = self.agent.process_message(text)
        self.assertIsNone(result)

    def test_failure(self):
        text = "Transaction of ₹200 to Uber failed due to insufficient funds."
        result = self.agent.process_message(text)
        self.assertIsNotNone(result)
        self.assertEqual(result['status'], 'failed')
        self.assertEqual(result['merchant'], 'Uber')

    def test_ippb_format(self):
        text = 'A/C X4952 Debit Rs.100.00 for UPI to abhinav  ravi on 12-01-26 Ref 601202411884. Avl Bal Rs.669.76. If not you? SMS FREEZE "full a/c" to 7669034700-IPPB'
        result = self.agent.process_message(text)
        self.assertIsNotNone(result)
        self.assertEqual(result['amount'], 100.0)
        self.assertEqual(result['type'], 'debit')
        self.assertEqual(result['merchant'], 'abhinav ravi')

    def test_mixed_debounce_credit(self):
        # Case where both 'debited' and 'credited' appear
        text = "Your a/c no. XXXX40519 is debited for Rs.18.88 on 17/01/26 10:20 PM and credited to a/c no. XXXXXXX52251 (UPI Ref no 638368508557)-Kerala Gramin Bank"
        result = self.agent.process_message(text)
        self.assertIsNotNone(result)
        self.assertEqual(result['amount'], 18.88)
        self.assertEqual(result['type'], 'debit')



if __name__ == '__main__':
    unittest.main()
