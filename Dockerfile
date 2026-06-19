FROM python:3.12-slim

# Dépendances système pour WeasyPrint + Pandoc
RUN apt-get update && apt-get install -y --no-install-recommends \
    pandoc \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libharfbuzz0b \
    libffi-dev \
    libcairo2 \
    libgdk-pixbuf2.0-0 \
    fonts-liberation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# WeasyPrint via pip
RUN pip install --no-cache-dir weasyprint==62.3

WORKDIR /cv

COPY . .

CMD ["make", "build"]
