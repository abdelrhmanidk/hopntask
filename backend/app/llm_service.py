import os
from openai import OpenAI
from dotenv import load_dotenv
from rag_service import RAGService
from memory_service import memory

# Load environment variables from .env file
load_dotenv()

class ReceiptAssistant:
    def __init__(self):
        # Initialize RAG service
        self.rag_service = RAGService()
        
        # Initialize OpenAI client with GitHub configuration
        self.client = OpenAI(
            base_url="https://models.github.ai/inference",
            api_key=os.environ.get("GITHUB_TOKEN")
        )
        
    async def ask(self, query):
        """
        Process a user query using RAG:
        1. Get relevant context using RAGService
        2. Construct a prompt with context and query
        3. Get response from LLM
        """
        # Get relevant context from RAG service
        context = await self.rag_service.get_relevant_context(query)
        
        # Get chat history
        chat_history = memory.get_chat_history()
        
        # Construct the prompt with context and chat history
        system_prompt = f"""You are a helpful assistant specialized in analyzing receipt and expense data. 
Use the following receipt context and chat history to answer the user's question. You can help with:
- Summarizing spending patterns
- Finding specific receipts or purchases
- Calculating totals for specific periods or categories
- Providing insights on spending habits

If you don't have enough information or the context doesn't contain what's being asked, 
let the user know politely.

CONTEXT:
{context}

CHAT HISTORY:
{chat_history if chat_history else 'No previous conversation'}"""

        # Add user message to memory
        memory.add_user_message(query)

        # Get response from OpenAI with GitHub configuration
        response = self.client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": system_prompt,
                },
                {
                    "role": "user",
                    "content": query,
                }
            ],
            model="openai/gpt-4.1",
            temperature=0.7,
            top_p=1.0
        )
        
        ai_response = response.choices[0].message.content
        
        # Add AI response to memory
        memory.add_ai_message(ai_response)
        
        return ai_response

# Create a singleton instance
ai = ReceiptAssistant()