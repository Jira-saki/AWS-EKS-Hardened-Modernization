from fastapi import FastAPI
import os

app = FastAPI()
APP_VERSION = os.getenv("APP_VERSION", "v1.0.0")

@app.get("/healthz")
def health_check():
    return {"status": "ok"}

@app.get("/version")
def get_version():
    return {"version": APP_VERSION}
