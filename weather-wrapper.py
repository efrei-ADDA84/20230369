import sys
import os
import requests

def get_weather(latitude, longitude):
    api_key = os.getenv("API_KEY")
    if not api_key:
        raise ValueError("API_KEY environment variable not set")
    
    url = f"http://api.openweathermap.org/data/2.5/weather?lat={latitude}&lon={longitude}&appid={api_key}&units=metric"
    response = requests.get(url)
    data = response.json()
    return data

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

if __name__ == "__main__":
    
    latitude = os.getenv("LAT")
    longitude = os.getenv("LONG")

    if not latitude or not longitude:
        print("Error: LATITUDE and LONGITUDE environment variables not set")
        sys.exit(1)

    latitude = float(latitude)
    longitude = float(longitude)

    response = get_weather(latitude, longitude)

    if response["cod"] == 200:
        print(format_weather_data(response))
    else:
        print("Error: ", response["message"])
