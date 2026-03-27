from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import io
from google import genai
from google.api_core import exceptions
from groq import Groq
from openai import OpenAI
import json
import re
import os
import time
import requests

app = Flask(__name__)
CORS(app) # Enable CORS for all routes

# --- CONFIGURATION ---
from dotenv import load_dotenv
load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")
GEOAPIFY_API_KEY = os.getenv("GEOAPIFY_API_KEY", "")

gemini_client = genai.Client(api_key=GEMINI_API_KEY)
groq_client = Groq(api_key=GROQ_API_KEY)
openai_client = OpenAI(api_key=OPENAI_API_KEY)

# --- CHAT MEMORY STORAGE ---
# Simple in-memory storage: { session_id: [messages] }
chat_memory = {}

# --- SMART GENERATE FUNCTION ---
def smart_generate(prompt, is_json=True):
    messages = [{"role": "user", "content": prompt}]
    
    # Try OpenAI first (Most stable for JSON)
    try:
        print(f"🤖 Calling OpenAI (gpt-4o-mini)... JSON_MODE={is_json}")
        extra_args = {}
        if is_json:
            extra_args["response_format"] = {"type": "json_object"}
        
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            **extra_args
        )
        content = response.choices[0].message.content
        if content:
            print("✅ OpenAI Success")
            return content
    except Exception as e:
        print(f"⚠️ OpenAI failed: {e}")

    # Try Gemini second
    try:
        print("🤖 Calling Gemini (gemini-1.5-flash)...")
        # For Gemini, we can ensure JSON by appending it to the prompt if not already there
        # but the main generate_plan prompt already has it.
        response = gemini_client.models.generate_content(
            model="gemini-1.5-flash",
            contents=prompt
        )
        if response.text:
            print("✅ Gemini Success")
            return response.text
    except Exception as e:
        print(f"⚠️ Gemini failed: {e}")
    
    # Try Groq third
    try:
        print("🤖 Calling Groq (llama-3.3-70b-versatile)...")
        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages
        )
        content = response.choices[0].message.content
        if content:
            print("✅ Groq Success")
            return content
    except Exception as e:
        print(f"⚠️ Groq failed: {e}")

    return None

UNSPLASH_ACCESS_KEY = os.getenv("UNSPLASH_ACCESS_KEY", "")

# --- NEW: Get Destination Image from Google Places API ---
def get_destination_image(query):
    print(f"📸 Fetching Google Places photo for: '{query}'")
    try:
        # Step 1: Find the place and its photo reference
        import requests.utils
        search_url = f"https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input={requests.utils.quote(query)}&inputtype=textquery&fields=photos&key={GOOGLE_MAPS_API_KEY}"
        
        response = requests.get(search_url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            if data['status'] == 'OK' and data.get('candidates') and data['candidates'][0].get('photos'):
                photo_ref = data['candidates'][0]['photos'][0]['photo_reference']
                
                # Step 2: Construct the valid Photo URL
                photo_url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference={photo_ref}&key={GOOGLE_MAPS_API_KEY}"
                
                # Step 3: Resolve the redirect to avoid CORS issues on Flutter Web
                redirect_res = requests.get(photo_url, allow_redirects=False, timeout=5)
                if redirect_res.status_code in [301, 302, 303, 307, 308]:
                    final_url = redirect_res.headers.get('Location', photo_url)
                else:
                    final_url = photo_url
                
                # Step 4: Use a backend proxy to bypass CORS entirely for Flutter Web
                # The frontend will call our own backend, which then fetches the image
                proxy_url = f"{request.host_url}proxy_image?url={requests.utils.quote(final_url)}"
                print(f"✅ Google Places Success: Proxy URL generated for '{query}'")
                return proxy_url
            else:
                print(f"⚠️ No Google Places photos found for '{query}'")
        else:
            print(f"❌ Google Places API Error: {response.status_code}")
            
    except Exception as e:
        print(f"⚠️ Error during Google Places fetch: {e}")
    
    # RELIABLE PRIMARY FALLBACK: Pollinations AI
    try:
        import urllib.parse
        best_term = query.replace("Exploring ", "").replace("Visit ", "").strip()
        detailed_prompt = f"professional travel photography of {best_term}, world famous landmark, sunny day, 8k"
        encoded = urllib.parse.quote(detailed_prompt)
        poll_url = f"https://image.pollinations.ai/prompt/{encoded}?width=1024&height=768&nologo=true"
        proxy_url = f"{request.host_url}proxy_image?url={requests.utils.quote(poll_url)}"
        print(f"🚀 Using Fallback Pollinations for: {best_term}")
        return proxy_url
    except:
        return "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&q=80&w=800"

# --- NEW: Image Proxy to Bypass CORS ---
@app.route('/proxy_image')
def proxy_image():
    image_url = request.args.get('url')
    if not image_url:
        return "URL parameter is missing", 400
    
    try:
        # Fetch the actual image
        response = requests.get(image_url, stream=True, timeout=10)
        
        if response.status_code == 200:
            # Wrap the content in a BytesIO object for streaming
            img_io = io.BytesIO(response.content)
            # Return with permissive headers
            res = send_file(img_io, mimetype=response.headers.get('Content-Type', 'image/jpeg'))
            res.headers['Access-Control-Allow-Origin'] = '*'
            return res
        else:
            return f"Failed to fetch image: {response.status_code}", 500
            
    except Exception as e:
        print(f"Proxy Error: {e}")
        return str(e), 500

# --- NEW: Get Route Info from Google Maps ---
def get_route_info(origin, destination):
    try:
        print(f"Fetching route from {origin} to {destination}")
        url = f"https://maps.googleapis.com/maps/api/directions/json?origin={origin}&destination={destination}&key={GOOGLE_MAPS_API_KEY}"
        response = requests.get(url)
        data = response.json()
        if data['status'] == 'OK':
            route = data['routes'][0]['legs'][0]
            polyline = data['routes'][0]['overview_polyline']['points']
            # Escape the polyline for the URL
            import urllib.parse
            encoded_polyline = urllib.parse.quote(polyline)
            map_url = f"https://maps.googleapis.com/maps/api/staticmap?size=600x400&path=enc:{encoded_polyline}&key={GOOGLE_MAPS_API_KEY}"
            
            return {
                "distance": route['distance']['text'],
                "duration": route['duration']['text'],
                "polyline": polyline,
                "map_url": map_url
            }
        elif data['status'] == 'ZERO_RESULTS':
            print("Google Maps: No driving/walking route found (likely cross-continent).")
            return {
                "distance": "Flight required",
                "duration": "Depends on flights",
                "map_url": None
            }
        else:
            print(f"Google Maps Directions API error: {data['status']} - {data.get('error_message')}")
    except Exception as e:
        print(f"Error fetching route: {e}")
    return None

# --- ROUTE 1: TRAVEL PLAN ---
@app.route('/generate_plan', methods=['POST'])
def generate_plan():
    destination = "Unknown"
    source = "Your Location"
    style = "Standard"
    try:
        data = request.get_json()
        source = data.get('source', 'Your Location') 
        destination = data.get('destination')
        days_str = data.get('days', '3 Days')
        # Extract number from "3 Days"
        days_num = 3
        try:
            days_num = int(re.search(r'\d+', days_str).group())
        except:
            pass

        style = data.get('style', 'Adventure')
        interests = data.get('interests', [])
        budget = data.get('budget', 'Budget')

        print(f"🚀 Generating plan from {source} to {destination} for {days_num} days...")

        prompt = f"""
        Act as an expert local travel guide and trip planner. 
        Create a comprehensive, day-by-day travel itinerary for a trip from {source} to {destination}.
        
        TRIP DETAILS: 
        - Duration: {days_num} days
        - Travel Style: {style}
        - User Interests: {', '.join(interests)}
        - Budget: {budget}
        
        REQUIREMENTS:
        1. Provide a specific, structured plan for EACH of the {days_num} days.
        2. Prioritize world-famous landmarks and highly-rated tourist attractions.
        3. Include a detailed budget breakdown in local currency.
        4. Suggest 3 specific, real hotels (Budget, Mid-range, Luxury).
        5. For each day, include:
           - A catchy day title.
           - Detailed description of activities (morning, afternoon, evening).
           - Specific local transport tip.
           - A local dish or restaurant recommendation.
           - A 'location_query' which is the name of the most iconic spot for that day (for map/image fetching).
        
        STRICT OUTPUT FORMAT (JSON):
        {{
          "summary": "Professional overview of the trip and travel advice.",
          "budget_breakdown": {{
            "flights": "estimated cost",
            "hotels": "estimated total cost",
            "food": "estimated cost",
            "activities": "estimated cost",
            "total_estimated": "total sum"
          }},
          "hotel_suggestions": [
            {{ "name": "Real Hotel Name", "price_per_night": "cost", "description": "Short reasoning" }}
          ],
          "itinerary": [
            {{
              "day": 1,
              "title": "Arrival & Initial Exploration",
              "description": "Step-by-step activities for the day...",
              "transport": "Specific transport advice...",
              "food_recommendation": "What to eat...",
              "about": "A fun local fact or historical note...",
              "location_query": "Specific Landmark Name"
            }}
          ]
        }}
        
        Ensure you generate exactly {days_num} entries in the 'itinerary' array.
        Return ONLY the JSON object.
        """

        response_text = smart_generate(prompt)
        if response_text is None:
            raise Exception("AI Generation failed")

        print("--- RAW AI RESPONSE RECEIVED ---")
        # print(response_text) # Log if needed

        # Enhanced JSON Extraction
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            cleaned_text = match.group(0)
        else:
            cleaned_text = response_text.strip()
            if "```json" in cleaned_text:
                cleaned_text = cleaned_text.split("```json")[1].split("```")[0].strip()
            elif "```" in cleaned_text:
                cleaned_text = cleaned_text.split("```")[1].split("```")[0].strip()
        
        try:
            plan = json.loads(cleaned_text)
        except json.JSONDecodeError:
            # Try one more time with simple cleanup
            cleaned_text = cleaned_text.replace('\n', ' ').replace('\r', '')
            plan = json.loads(cleaned_text)

        # Ensure itinerary exists
        if 'itinerary' not in plan or not plan['itinerary']:
            raise Exception("Itinerary missing in AI response")

        # Enrich with Images and Per-day Maps (Wrap in try-except per item)
        for day in plan['itinerary']:
            try:
                query = day.get('location_query', f"{destination} landmark")
                image_url = get_destination_image(query)
                day['image_url'] = image_url
                
                import urllib.parse
                encoded_loc = urllib.parse.quote(query)
                day['map_url'] = f"https://maps.googleapis.com/maps/api/staticmap?center={encoded_loc}&zoom=14&size=400x300&markers=color:red%7C{encoded_loc}&key={GOOGLE_MAPS_API_KEY}"
            except Exception as item_err:
                print(f"Error enriching day {day.get('day')}: {item_err}")
                day['image_url'] = "https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&q=80&w=800"

        # Enrich with Route
        try:
            route_info = get_route_info(source, destination)
            if route_info:
                plan['route'] = route_info
                plan['summary'] += f" The estimated distance is {route_info['distance']}."
        except:
            pass

        return jsonify(plan)

    except Exception as e:
        print(f"❌ Server Error: {e}")
        # Create a more dynamic fallback itinerary instead of just Day 1
        fallback_itinerary = []
        try:
            days_num = int(re.search(r'\d+', data.get('days', '1')).group())
        except:
            days_num = 1
            
        for i in range(1, days_num + 1):
            fallback_itinerary.append({
                "day": i,
                "title": f"Day {i}: Exploring {destination}",
                "description": f"Enjoy a beautiful day exploring the landmarks of {destination}. Visit the local markets and historical sites.",
                "transport": "Local Taxi or Public Transit",
                "about": f"{destination} is known for its incredible culture and scenery.",
                "image_url": "https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&q=80&w=800"
            })

        return jsonify({
            "summary": f"Welcome to {destination}. We've drafted a standard {style} plan for you starting from {source}. (AI model currently busy, providing fallback plan).",
            "budget_breakdown": {
                "flights": "Check local rates",
                "hotels": "₹15,000",
                "food": "₹5,000",
                "activities": "₹3,000",
                "total_estimated": "₹23,000+"
            },
            "itinerary": fallback_itinerary
        })

# --- ROUTE 2: CHAT BOT ---
@app.route('/chat', methods=['POST'])
def chat_bot():
    try:
        data = request.get_json()
        user_message = data.get('message')
        session_id = data.get('session_id', 'default_session')
        
        # Initialize memory if not exists
        if session_id not in chat_memory:
            chat_memory[session_id] = []
            
        # Get history (limit to last 10 messages for context)
        history = chat_memory[session_id][-10:]
        
        # --- ENHANCED PROMPT WITH HISTORY ---
        system_prompt = """
        You are TravelAI, an enthusiastic, expert local travel guide and world-class adventurer. 
        Your personality is helpful, knowledgeable, and slightly adventurous.
        
        RULES:
        1. Keep responses concise but value-packed (max 3-4 sentences).
        2. Always use at least 1-2 relevant emojis (🌍, ✈️, 🍱).
        3. Provide one "Pro Tip" if relevant.
        4. REMEMBER the conversation history for context.
        """
        
        # Construct messages for smart_generate (OpenAI format style)
        messages = [{"role": "system", "content": system_prompt}]
        for msg in history:
            messages.append({"role": msg['role'], "content": msg['text']})
        messages.append({"role": "user", "content": user_message})
        
        # We need to adapt smart_generate to take full message list
        # For simplicity in this step, we'll format it as a single prompt for now
        history_text = "\n".join([f"{m['role']}: {m['content']}" for m in messages])
        
        response_text = smart_generate(history_text, is_json=False)
        
        if response_text is None:
            return jsonify({"response": "I'm charting some new routes right now! 🗺️ Ask me again in a moment!"})
        
        # Update memory
        chat_memory[session_id].append({"role": "user", "text": user_message})
        chat_memory[session_id].append({"role": "assistant", "text": response_text})
        
        return jsonify({"response": response_text})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- ROUTE 3: WEATHER INFO ---
@app.route('/weather', methods=['POST'])
def get_weather():
    try:
        data = request.get_json()
        location = data.get('location')
        
        # Simple Logic: We'll use the smart_generate to "predict" typical weather
        # or simulate an API call for this demo.
        prompt = f"""
        Provide current typical weather for {location} in JSON format.
        Include temperature in Celsius, a short description (sunny, rainy, etc), 
        an emoji, and the 'Best time to visit'.
        Format: {{ 'temp': 22, 'description': 'Sunny', 'emoji': '☀️', 'best_time': 'April-May' }}
        """
        response_text = smart_generate(prompt)
        
        # Cleanup JSON
        cleaned_text = response_text.strip()
        if "```json" in cleaned_text:
            cleaned_text = cleaned_text.split("```json")[1].split("```")[0].strip()
        
        weather_data = json.loads(cleaned_text)
        return jsonify(weather_data)
    except Exception as e:
        return jsonify({"temp": "24", "description": "Cloudy", "emoji": "☁️", "best_time": "Year-round"}), 200

# --- ROUTE 4: SMART SUGGESTIONS ---
@app.route('/suggestions', methods=['POST'])
def get_suggestions():
    try:
        data = request.get_json()
        location = data.get('location')
        prompt = f"Given that someone is visiting {location}, suggest 3 nearby must-visit cities or attractions. Return a JSON list of objects with 'name' and 'reason'."
        response_text = smart_generate(prompt)
        
        cleaned_text = response_text.strip()
        if "```json" in cleaned_text:
            cleaned_text = cleaned_text.split("```json")[1].split("```")[0].strip()
            
        suggestions = json.loads(cleaned_text)
        return jsonify(suggestions)
    except:
        return jsonify([{"name": "Nearby Spot", "reason": "Highly recommended!"}])

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5000)
