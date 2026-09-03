# ── Stage 1: dependency builder ───────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Stage 2: minimal runtime image ────────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Create a dedicated non-root system user/group before switching to it.
# Numeric-only USER without a corresponding passwd entry works at runtime
# but breaks tools that call getpwuid(). Explicit adduser ensures
# compatibility and satisfies runAsNonRoot admission checks cleanly.
RUN addgroup --system --gid 10001 appgroup && \
    adduser  --system --uid 10001 --gid 10001 --no-create-home appuser

COPY --from=builder /opt/venv /opt/venv
COPY main.py .

ENV PATH="/opt/venv/bin:$PATH"

USER 10001
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
