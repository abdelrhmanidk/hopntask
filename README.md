# HopnTask - Expense Tracking App

HopnTask is a modern expense tracking application that helps you manage your expenses with features like receipt scanning, manual entry, and AI-powered categorization.

## Screenshots

<div align="center">
  <img src="images/IMG_7700.PNG" alt="Home Screen" width="250"/>
  <img src="images/IMG_7702.PNG" alt="Add Expense" width="250"/>
  <img src="images/IMG_7709.PNG" alt="Category Selection" width="250"/>
  <br/>
  <img src="images/IMG_7710.PNG" alt="Expense Details" width="250"/>
  <img src="images/IMG_7711.PNG" alt="Settings" width="250"/>
</div>

## Technical Architecture

### Backend Implementation

The backend is built using FastAPI and implements a RAG (Retrieval-Augmented Generation) system for intelligent expense management and natural language interaction.

#### Core Components:

1. **FastAPI Backend** (`main.py`)
   - RESTful endpoints:
     - `/ai/chat` - Chat interface for expense queries
     - `/receipts/store` - Store new receipts with metadata
     - `/ai/chat/clear` - Clear chat history
     - `/health` - Health check endpoint
   - CORS middleware for cross-origin requests
   - Request validation using Pydantic models
   - Comprehensive error handling and logging

2. **RAG System** (`rag_service.py`)
   - **ChromaDB Integration**
     - Persistent client with local storage (`./chroma_store`)
     - Collection: "receipts" for storing expense data
     - Vector embeddings using `all-MiniLM-L6-v2` model
     - Metadata storage for receipts including:
       - Title
       - Date
       - Total amount
       - Timestamp
   
   - **Context Retrieval**
     - Semantic search using vector embeddings
     - Configurable number of results (default: 3)
     - Returns formatted context with receipt details
     - Source tracking for retrieved documents

3. **LLM Service** (`llm_service.py`)
   - Integration with GitHub's inference API
   - Model: `openai/gpt-4.1`
   - Context-aware responses using:
     - RAG-retrieved receipt context
     - Conversation history
   - Specialized system prompt for expense analysis
   - Temperature: 0.7 for balanced creativity/accuracy

4. **Memory Service** (`memory_service.py`)
   - Conversation history management
   - Uses `ConversationBufferMemory` from LangChain
   - Maintains chat history with:
     - User messages
     - AI responses
   - Methods for:
     - Adding messages
     - Retrieving history
     - Clearing conversation

### Data Flow

1. **Receipt Storage Flow**
   ```
   Receipt Data → FastAPI Endpoint → 
   ChromaDB Storage (with metadata) → 
   Vector Embedding Generation
   ```

2. **Chat Query Flow**
   ```
   User Query → LLM Service → 
   RAG Context Retrieval → 
   Memory Service (History) → 
   Context-Augmented Response
   ```

### Environment Setup

Required environment variables:
```env
GITHUB_TOKEN=your_github_token  # For LLM API access
```

### API Endpoints

1. **Chat Interface** (`POST /ai/chat`)
   - Request: `{ "query": "string" }`
   - Response: `{ "response": "string" }`
   - Uses RAG and conversation history

2. **Receipt Storage** (`POST /receipts/store`)
   - Stores receipt data with:
     - Title
     - Total
     - Date
     - Items list
     - Raw OCR text
   - Automatically generates embeddings
   - Stores in ChromaDB with metadata

3. **Chat Management** (`POST /ai/chat/clear`)
   - Clears conversation history
   - Resets memory service

### Key Features

- **AI-Powered Expense Management**
  - Intelligent receipt categorization
  - Natural language expense queries
  - Context-aware expense analysis
  - Automated data extraction

- **Smart Search and Retrieval**
  - Semantic search across expenses
  - Similar receipt finding
  - Category-based filtering
  - Date-range queries

- **Interactive Chat Interface**
  - Natural language interaction
  - Context-aware responses
  - Expense history exploration
  - Spending pattern analysis

## Features

- 📱 Modern Flutter UI with iOS-style design
- 📷 Receipt scanning with OCR
- 💰 Manual expense entry
- 📊 Expense categorization
- 🔍 AI-powered expense search
- 📈 Expense statistics and insights
- 📤 Data export to CSV

## Prerequisites

- Flutter SDK (latest stable version)
- Python 3.11 or higher
- Node.js 18 or higher (for development tools)
- iOS Simulator (for iOS development)
- Android Studio & Android SDK (for Android development)

## Project Structure

```
hopntask/
├── lib/                    # Flutter frontend code
│   ├── screens/           # App screens
│   ├── widgets/           # Reusable widgets
│   ├── services/          # Service classes
│   ├── models/            # Data models
│   ├── blocs/             # State management
│   └── data/              # Data repositories
├── backend/               # Python backend
│   ├── app/              # FastAPI application
│   ├── services/         # Backend services
│   └── requirements.txt   # Python dependencies
└── assets/               # Static assets
```

## Setup Instructions

### Frontend Setup

1. Install Flutter:
   ```bash
   # macOS (using Homebrew)
   brew install flutter

   # Verify installation
   flutter doctor
   ```

2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/hopntask.git
   cd hopntask
   ```

3. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

4. Create a `.env` file in the root directory:
   ```bash
   cp .env.example .env
   ```
   Edit the `.env` file with your configuration:
   ```
   BACKEND_URL=http://localhost:8007
   CHROMA_URL=http://localhost:8007
   ```

### Backend Setup

1. **Environment Setup**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: .\venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Required Environment Variables**
   ```env
   OPENAI_API_KEY=your_openai_api_key
   CHROMA_DB_PATH=path_to_chroma_db
   MODEL_NAME=gpt-3.5-turbo  # or your preferred model
   ```

3. **Starting the Backend**
   ```bash
   uvicorn app.main:app --reload
   ```

4. **API Documentation**
   - Swagger UI: `http://localhost:8000/docs`
   - ReDoc: `http://localhost:8000/redoc`

### Running the App

1. Start the backend server (if not already running):
   ```bash
   cd backend
   source venv/bin/activate  # or .\venv\Scripts\activate on Windows
   uvicorn app.main:app --reload --port 8007
   ```

2. In a new terminal, run the Flutter app:
   ```bash
   # For iOS
   flutter run -d ios

   # For Android
   flutter run -d android
   ```

## Development

### Frontend Development

- The app uses BLoC pattern for state management
- Services are provided using `RepositoryProvider`
- UI follows iOS design guidelines using Cupertino widgets
- FontAwesome icons are used throughout the app

### Backend Development

- FastAPI for the backend API
- ChromaDB for vector storage
- OCR service for receipt processing
- Environment variables for configuration

## Dependencies

### Frontend Dependencies
- flutter_bloc: State management
- font_awesome_flutter: Icons
- path_provider: File system access
- share_plus: File sharing
- http: API communication
- intl: Date formatting
- flutter_dotenv: Environment variables

### Backend Dependencies
- fastapi: Web framework
- uvicorn: ASGI server
- chromadb: Vector database
- pytesseract: OCR processing
- opencv-python: Image processing
- python-multipart: File uploads
- python-dotenv: Environment variables

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository or contact the maintainers.

## Acknowledgments

- Flutter team for the amazing framework
- FastAPI team for the backend framework
- ChromaDB team for the vector database
- All contributors who have helped with the project
