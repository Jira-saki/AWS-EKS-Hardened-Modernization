import os
import time
import math
from fastapi import FastAPI, Query
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI(title="secure-api", docs_url=None, redoc_url=None)

APP_VERSION = os.getenv("APP_VERSION", "v1.0.0")


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/version")
def version():
    return {"version": APP_VERSION}


@app.get("/cpu-burn")
def cpu_burn(
    duration: float = Query(
        default=0.1,
        ge=0.01,
        le=5.0,
        description="Burn duration in seconds (0.01–5.0). Drives CPU utilisation for HPA validation.",
    ),
):
    """Synthetic CPU load endpoint. Used by k6 spike test to trigger HPA scale-out."""
    start_time = time.time()
    while time.time() - start_time < duration:
        _ = [math.sqrt(i) for i in range(1000)]
    return {"status": "burn completed", "duration_sec": round(duration, 3)}


# Expose Prometheus /metrics endpoint automatically (RED metrics + custom histograms)
Instrumentator().instrument(app).expose(app)
