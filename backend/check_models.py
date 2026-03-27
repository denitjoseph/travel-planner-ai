import os
from google import genai
from dotenv import load_dotenv

load_dotenv()

# Use API key from environment variables
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

print("Fetching available models...")
try:
    for m in client.models.list():
        print(f"- {m.name}")
except Exception as e:
    print(f"Error: {e}")
