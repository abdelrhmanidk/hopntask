import cv2
import numpy as np
import pytesseract
from PIL import Image
import io
import base64
from datetime import datetime
import re
from dateutil import parser

class OCRService:
    def __init__(self):
        # Use LSTM OCR engine + block mode (psm 6 = uniform blocks)
        self.custom_config = r'--oem 3 --psm 6'

    def preprocess_image(self, image):
        """Enhance image for better OCR using OpenCV techniques."""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        gray = cv2.bilateralFilter(gray, 11, 17, 17)  # reduce noise, keep edges
        gray = cv2.adaptiveThreshold(
            gray, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            11, 2
        )
        return gray

    def extract_text(self, image):
        """Perform OCR using pytesseract on preprocessed image."""
        processed_image = self.preprocess_image(image)
        text = pytesseract.image_to_string(processed_image, config=self.custom_config)
        return text

    def extract_vendor(self, text):
        """Try to identify vendor name using keywords like 'From:', else fallback to header."""
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        keyword_patterns = ['from', 'vendor', 'store', 'sold by', 'company']

        for line in lines:
            lower = line.lower()
            if any(k in lower for k in keyword_patterns):
                parts = re.split(r'[:\-]', line, maxsplit=1)
                if len(parts) == 2:
                    candidate = parts[1].strip()
                    if len(candidate) > 2:
                        return candidate.upper()

        # fallback: first few lines that look like names
        for line in lines[:7]:
            if not any(word in line.lower() for word in ['date', 'time', 'invoice', 'amount', 'total']):
                if len(re.findall(r'[A-Za-z]', line)) > 3:
                    return line.upper()

        return "Unknown Vendor"

    def extract_date(self, text):
        """Enhanced date extractor with keyword support like 'Due Date'."""
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        date_keywords = ['date', 'due date', 'invoice date', 'purchase date', 'order date']
        date_patterns = [
            r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
            r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})',
            r'(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})',
            r'([A-Za-z]{3,9}\s+\d{1,2},?\s+\d{2,4})',
        ]

        # First pass: look for lines with keywords
        for line in lines:
            if any(k in line.lower() for k in date_keywords):
                for pattern in date_patterns:
                    match = re.search(pattern, line)
                    if match:
                        try:
                            parsed = parser.parse(match.group(), fuzzy=True)
                            if parsed.year <= datetime.now().year + 1:
                                return parsed.strftime('%Y-%m-%d')
                        except:
                            continue

        # Fallback: match any date in full text
        full_text = '\n'.join(lines)
        for pattern in date_patterns:
            matches = re.findall(pattern, full_text)
            for match in matches:
                try:
                    parsed = parser.parse(match, fuzzy=True)
                    if parsed.year <= datetime.now().year + 1:
                        return parsed.strftime('%Y-%m-%d')
                except:
                    continue

        return "Unknown"

    def extract_total(self, text):
        """Find the total amount in receipt by scanning relevant lines and keywords."""
        candidates = []
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        total_keywords = ['total', 'amount due', 'balance', 'amount']

        for line in lines:
            if any(kw in line.lower() for kw in total_keywords):
                match = re.search(r'(\d+[\.,]?\d{2})', line)
                if match:
                    try:
                        value = float(match.group().replace(',', ''))
                        candidates.append((line.lower(), value))
                    except:
                        continue

        if candidates:
            # Prefer line with keyword 'total' and highest amount
            candidates.sort(key=lambda x: ('total' not in x[0], -x[1]))
            return candidates[0][1]

        # fallback: look for lone currency values near end of lines
        for line in reversed(lines):
            match = re.search(r'\$?\s?(\d+[\.,]?\d{2})$', line)
            if match:
                try:
                    return float(match.group(1).replace(',', ''))
                except:
                    continue

        return 0.0

    def process_receipt(self, image_data):
        """Main method to decode base64 image, run OCR, and extract key fields."""
        try:
            # Decode image
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            opencv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)

            # Run OCR
            text = self.extract_text(opencv_image)

            # Extract fields
            vendor = self.extract_vendor(text)
            date = self.extract_date(text)
            total = self.extract_total(text)

            return {
                'vendor_name': vendor,
                'date': date,
                'total_amount': total,
                'raw_text': text
            }

        except Exception as e:
            raise Exception(f"Error processing receipt: {str(e)}")
