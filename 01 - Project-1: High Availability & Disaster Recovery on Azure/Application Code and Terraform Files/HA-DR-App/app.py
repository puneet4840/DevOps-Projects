from flask import Flask
import os
import socket


app = Flask(__name__)


@app.route("/")
def home():
    return {
        "message": "HA-DR Application is running",
        "region": os.getenv("REGION_NAME", "unknown"),
        "hostname": socket.gethostname()
    }


@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
