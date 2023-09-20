# kyso-nbdime image
ARG BASE_VERSION=fixme
FROM registry.kyso.io/docker/kyso-nbdime:${BASE_VERSION}
LABEL maintainer="Sergio Talens-Oliag <sto@kyso.io>"
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
EXPOSE 3005
CMD [ "/usr/local/bin/flask", "run", "-h", "0.0.0.0", "-p", "3005" ]
