# from fastapi import FastAPI, HTTPException
# from pydantic import BaseModel
# from services.chroma_db2 import ai

# app = FastAPI(
#     title="ACS Chatbot API",
#     description="API for interacting with the ACS (Acute Coronary Syndrome) chatbot",
#     version="1.0.0"
# )

# class ChatRequest(BaseModel):
#     query: str

# class ChatResponse(BaseModel):
#     response: str

# @app.post("/chat", response_model=ChatResponse)
# async def chat(request: ChatRequest):
#     try:
#         response = ai.ask(request.query)
#         return ChatResponse(response=response)
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(app, host="0.0.0.0", port=8000) 