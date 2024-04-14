from flask import Flask, request, jsonify
import os
import requests

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
    formatted_weather = f"Weather in {weather_data['name']} ({weather_data['coord']['lat']}, {weather_data['coord']['lon']}):\n"
    formatted_weather += f"Description: {weather_data['weather'][0]['description']}\n"
    formatted_weather += f"Temperature: {weather_data['main']['temp']}°C\n"
    formatted_weather += f"Feels Like: {weather_data['main']['feels_like']}°C\n"
    formatted_weather += f"Minimum Temperature: {weather_data['main']['temp_min']}°C\n"
    formatted_weather += f"Maximum Temperature: {weather_data['main']['temp_max']}°C\n"
    formatted_weather += f"Humidity: {weather_data['main']['humidity']}%\n"
    formatted_weather += f"Wind Speed: {weather_data['wind']['speed']} m/s\n"
    formatted_weather += f"Wind Direction: {weather_data['wind']['deg']}°\n"
    return formatted_weather

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)