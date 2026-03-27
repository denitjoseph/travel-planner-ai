# TravelAI - Smart Travel Planner

TravelAI is an advanced travel planning application built with Flutter and Flask. It leverages multiple AI models to generate personalized itineraries, integrates Google Maps for routing, and uses Geoapify for destination imagery.

## 🚀 Key Features

- **Multi-AI Itinerary Generation**: Uses a fallback mechanism to ensure reliability:
    - **Primary**: Google Gemini 2.0 Flash
    - **Backup 1**: Groq (Llama 3 70B)
    - **Backup 2**: OpenAI GPT-4o
- **Intelligent Routing**: Automatically calculates distance and travel duration between locations via Google Maps Platform API.
- **Visual Itineraries**: Fetches beautiful destination and landmark images using Geoapify Places API.
- **Contextual AI Assistant**: Smart memory-enabled travel assistant for natural, context-aware conversations.
- **Voice Interaction (TTS/STT)**: Talk to the AI via your microphone and listen to its responses!
- **Premium Mobile UI**: 
    - Smooth Glassmorphism effects (frosted glass NavBar).
    - Premium Shimmer skeleton loaders.
    - Sleek compact cards and persistent mobile action bar.
- **Super Itineraries**: Includes Hotels, local Transport tips, and Food recommendations with detailed Budget Breakdown tables.
- **Interactive Chat Context**: Smart quick-action chips for real-time Weather checking and nearby city Suggestions.
- **Persistence & Exporting**: Save trips directly to Firebase, export as formatted PDF, or share quickly via WhatsApp.

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Flask (Python)
- **AIs**: Google Generative AI (genai), Groq, OpenAI
- **Map Services**: Google Maps Platform, Geoapify
- **Database**: Firebase Firestore
- **Auth**: Firebase Authentication

## 📦 Project Structure

```text
travel_user_app/
├── android/            # Android-specific configuration
├── backend/            # Python Flask backend
│   └── app.py          # Main backend API logic
├── ios/                # iOS-specific configuration
├── lib/                # Flutter source code
│   ├── screens/        # Main UI pages (Plan, Result, Chat, etc.)
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # App entry point
└── pubspec.yaml        # Flutter dependencies
```

## 🛠️ Setup Instructions

### 1. Backend Setup
1. Navigate to the `backend/` directory.
2. Install dependencies:
   ```bash
   pip install flask flask-cors google-generativeai groq openai requests python-dotenv
   ```
3. Set up your environment variables by copying the example file:
   ```bash
   cp .env.example .env
   ```
   *Open the newly created `.env` file and fill in your actual API keys.*
4. Run the backend server:
   ```bash
   python app.py
   ```
   The backend will run on `http://localhost:5000`.

### 2. Frontend Setup
1. Ensure you have Flutter installed.
2. From the root directory, fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## 🔑 API Configuration

The following APIs should be configured inside the `backend/.env` file:
- `GEMINI_API_KEY`: Google AI Studio
- `GROQ_API_KEY`: Groq Cloud
- `OPENAI_API_KEY`: OpenAI API
- `GOOGLE_MAPS_API_KEY`: Google Cloud Console
- `GEOAPIFY_API_KEY`: Geoapify Dashboard

> [!IMPORTANT]
> Ensure your API keys have the necessary permissions (Directions API for Google Maps, etc.) enabled.

## 📸 Screenshots

*(Add screenshots of your generated itineraries here!)*

---
Built with ❤️ by TravelAI Team
