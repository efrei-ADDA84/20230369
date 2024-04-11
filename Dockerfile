FROM cgr.dev/chainguard/python:latest-dev as builder

ENV OPENWEATHER_API_KEY="46fd963f2bcfce7bc3a7336b86a1ab5b"

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt --user

FROM cgr.dev/chainguard/python:latest

WORKDIR /app

COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY weather-wrapper.py .

ENTRYPOINT ["python", "weather-wrapper.py"]
