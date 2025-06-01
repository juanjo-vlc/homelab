FROM python:3.12-slim

WORKDIR /app

# Install poetry and project dependencies
RUN apt update && apt install -y --no-install-recommends apache2-dev
COPY pyproject.toml poetry.lock ./
RUN pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install




# Copy source
COPY src/ ./

EXPOSE 8000

CMD ["scripts/start.sh"]
