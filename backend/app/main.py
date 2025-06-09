from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel, ValidationError
from openai import OpenAI
import os
from dotenv import load_dotenv
from llm_service import ai
from rag_service import RAGService
from memory_service import memory
import chromadb
from datetime import datetime
import logging

# Load environment variables
load_dotenv()

app = FastAPI()

# Validate services on startup
@app.on_event("startup")
async def validate_services():
    try:
        # Initialize and validate RAG service
        rag_service = RAGService()
        # Test the collection access
        _ = rag_service.collection.count()
        logging.info("RAG service initialized successfully")
        
        # Initialize and validate memory service
        _ = memory.get_chat_history()
        logging.info("Memory service initialized successfully")
        
    except Exception as e:
        logging.error(f"Failed to initialize services: {str(e)}")
        raise RuntimeError(f"Failed to initialize services: {str(e)}")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ReceiptChatRequest(BaseModel):
    query: str

class ReceiptChatResponse(BaseModel):
    response: str

class ReceiptData(BaseModel):
    title: str
    total: float
    date: str
    items: list[dict]
    raw_text: str

@app.post("/ai/chat", response_model=ReceiptChatResponse)
async def receipt_chat(request: ReceiptChatRequest):
    try:
        response = await ai.ask(request.query)
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    error_details = []
    for error in exc.errors():
        error_details.append({
            'loc': ' -> '.join(str(loc) for loc in error['loc']),
            'msg': error['msg'],
            'type': error['type']
        })
    logging.error(f"Validation error in request to {request.url}: {error_details}")
    return HTTPException(status_code=422, detail=error_details)

@app.post("/receipts/store")
async def store_receipt(receipt: ReceiptData):
    try:
        logging.info(f"Processing receipt store request for {receipt.title}")
        # Use RAGService instance
        rag_service = RAGService()
        collection = rag_service.collection
        
        # Format the receipt data into a document
        receipt_text = f"""
Receipt from: {receipt.title}
Date: {receipt.date}
Total: ${receipt.total:.2f}

Items:
{chr(10).join([f"- {item['name']}: ${item['price']}" for item in receipt.items])}

Raw OCR Text:
{receipt.raw_text}
"""
        
        # Store in ChromaDB with metadata
        collection.add(
            documents=[receipt_text],
            metadatas=[{
                "title": receipt.title,
                "date": receipt.date,
                "total": receipt.total,
                "timestamp": datetime.now().isoformat()
            }],
            ids=[f"receipt_{datetime.now().timestamp()}"]
        )
        
        logging.info(f"Successfully stored receipt for {receipt.title}")
        return {"status": "success", "message": "Receipt stored successfully"}
    except ValidationError as e:
        logging.error(f"Validation error while processing receipt: {str(e)}")
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        logging.error(f"Error storing receipt: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ai/chat/clear")
async def clear_chat_history():
    try:
        memory.clear()
        return {"status": "success", "message": "Chat history cleared successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.on_event("shutdown")
async def shutdown_services():
    try:
        # Get RAG service instance
        rag_service = RAGService()
        # Close ChromaDB client
        rag_service.chroma_client.close()
        logging.info("Services shut down successfully")
    except Exception as e:
        logging.error(f"Error during shutdown: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001) 