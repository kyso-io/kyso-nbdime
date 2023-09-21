# kyso-nbdime image
ARG PYTHON_VERSION=3.11.1-alpine3.17

FROM python:${PYTHON_VERSION}
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
EXPOSE 3005
CMD [ "/usr/local/bin/flask", "run", "-h", "0.0.0.0", "-p", "3005" ]
