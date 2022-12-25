# Python base image (with the requirements installed)
ARG PYTHON_VERSION=fixme
FROM registry.kyso.io/docker/python:${PYTHON_VERSION}
LABEL maintainer="Sergio Talens-Oliag <sto@kyso.io>"
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
