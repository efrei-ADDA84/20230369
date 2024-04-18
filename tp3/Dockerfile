FROM python:3.12-alpine

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt --user

COPY weather-wrapper-api.py .

EXPOSE 80

ENTRYPOINT ["python", "weather-wrapper-api.py"]
