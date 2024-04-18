from flask import Flask, request, jsonify
import os
import requests
from waitress import serve

app = Flask(__name__)

@app.route('/')
def get_weather():
    latitude = request.args.get('lat')
    longitude = request.args.get('lon')
    
    api_key = os.getenv("API_KEY")
    if not api_key:
        return jsonify({"error": "API_KEY environment variable not set"}), 500

    url = f"http://api.openweathermap.org/data/2.5/weather?lat={latitude}&lon={longitude}&appid={api_key}&units=metric"
    response = requests.get(url)
    data = response.json()
    
    if response.status_code == 200:
        formatted_weather = format_weather_data(data)
        return jsonify({"weather": formatted_weather})
    else:
        return jsonify({"error": data["message"]}), response.status_code

def format_weather_data(weather_data):
    formatted_weather = {
        "location": weather_data['name'],
        "latitude": weather_data['coord']['lat'],
        "longitude": weather_data['coord']['lon'],
        "description": weather_data['weather'][0]['description'],
        "temperature": f"{weather_data['main']['temp']} degrees Celsius",
        "feels_like": f"{weather_data['main']['feels_like']} degrees Celsius",
        "minimum_temperature": f"{weather_data['main']['temp_min']} degrees Celsius",
        "maximum_temperature": f"{weather_data['main']['temp_max']} degrees Celsius",
        "humidity": f"{weather_data['main']['humidity']}%",
        "wind_speed": f"{weather_data['wind']['speed']} m/s",
        "wind_direction": f"{weather_data['wind']['deg']} degrees"
    }
    return formatted_weather

if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=80)