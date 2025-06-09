from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from app.services.ocr_service import OCRService
import uvicorn

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize OCR service
ocr_service = OCRService()

class ReceiptRequest(BaseModel):
    image: str  # Base64 encoded image

class ReceiptResponse(BaseModel):
    text: str
    vendor_name: str
    total_amount: float
    date: str
    items: list[str]

def preprocess_image(image):
    """Preprocess the image for better OCR results"""
    try:
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Apply adaptive thresholding
        thresh = cv2.adaptiveThreshold(
            blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2
        )
        
        # Denoise
        denoised = cv2.fastNlMeansDenoising(thresh)
        
        # Increase contrast
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        enhanced = clahe.apply(gray)
        
        return enhanced
    except Exception as e:
        logger.error(f"Error in image preprocessing: {str(e)}")
        return image

def extract_text_from_image(base64_image):
    """Extract text from the image using Tesseract OCR."""
    try:
        # Decode base64 image
        image_data = base64.b64decode(base64_image)
        image = Image.open(io.BytesIO(image_data))
        
        # Convert PIL Image to OpenCV format
        opencv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        
        # Preprocess image
        processed_image = preprocess_image(opencv_image)
        
        # Extract text using Tesseract
        text = pytesseract.image_to_string(processed_image)
        
        return text.strip()
    except Exception as e:
        logger.error(f"Error extracting text: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

def extract_total_amount(text):
    """Extract total amount from the text."""
    # Look for patterns like "Total: $XX.XX" or "TOTAL: $XX.XX"
    patterns = [
        r'Total:?\s*\$?\s*(\d+\.\d{2})',
        r'TOTAL:?\s*\$?\s*(\d+\.\d{2})',
        r'Amount:?\s*\$?\s*(\d+\.\d{2})',
        r'AMOUNT:?\s*\$?\s*(\d+\.\d{2})',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return float(match.group(1))
    
    return 0.0

def extract_vendor_name(text):
    """Extract vendor name from the text."""
    # Usually the vendor name is at the top of the receipt
    lines = text.split('\n')
    for line in lines[:5]:  # Check first 5 lines
        line = line.strip()
        if line and not any(char.isdigit() for char in line):
            return line
    return "Unknown Vendor"

def extract_date(text):
    """Extract date from the text."""
    # Look for common date patterns
    patterns = [
        r'\d{1,2}/\d{1,2}/\d{2,4}',
        r'\d{1,2}-\d{1,2}-\d{2,4}',
        r'\d{1,2}\.\d{1,2}\.\d{2,4}',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            return match.group(0)
    
    return datetime.now().strftime("%Y-%m-%d")

def extract_items(text):
    """Extract items from the text."""
    items = []
    lines = text.split('\n')
    
    for line in lines:
        line = line.strip()
        # Skip empty lines, totals, and dates
        if (line and 
            not re.search(r'Total|TOTAL|Amount|AMOUNT|Tax|TAX|Subtotal|SUBTOTAL', line) and
            not re.search(r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}', line)):
            items.append(line)
    
    return items

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/process-receipt")
async def process_receipt(request: ReceiptRequest):
    try:
        result = ocr_service.process_receipt(request.image)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8006, reload=True) 