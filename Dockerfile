FROM python:3.12.8-slim-bookworm

WORKDIR /app
ENV POETRY_VERSION=1.8.5
ENV PATH=/root/.local/bin:${PATH}
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    curl \
    make \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/* \
  && curl -sSL https://install.python-poetry.org | python3 -
ADD . ./
RUN poetry install
