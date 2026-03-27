from google import genai

# Paste your actual API Key here
client = genai.Client(api_key="AIzaSyBXaZRG20Nso9jER3RRcAwRUCTv0BhrcgQ")

print("Fetching available models...")
try:
    for m in client.models.list():
        print(f"- {m.name}")
except Exception as e:
    print(f"Error: {e}")