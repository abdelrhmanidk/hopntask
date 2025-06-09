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

## Features

- 📱 Modern Flutter UI with iOS-style design
- 📷 Receipt scanning with OCR
- 💰 Manual expense entry
- 📊 Expense categorization
- 🔍 AI-powered expense search
- 📈 Expense statistics and insights
- 📤 Data export to CSV
- 💾 Local storage with ChromaDB backup

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

1. Create and activate a Python virtual environment:
   ```bash
   cd backend
   python -m venv venv
   
   # On macOS/Linux
   source venv/bin/activate
   
   # On Windows
   .\venv\Scripts\activate
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Start the backend server:
   ```bash
   uvicorn app.main:app --reload --port 8007
   ```

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
