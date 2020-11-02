FROM ubuntu:latest

# ENV http_proxy http://cache.ha.univ-nantes.fr:3128
# ENV https_proxy http://cache.ha.univ-nantes.fr:3128

MAINTAINER Sylvain DAVID

RUN apt-get update -y && apt-get install -y python3-pip python3-dev build-essential
COPY ./app /app
WORKDIR /app
RUN pip3 install -r requirements.txt
ENTRYPOINT ["python3"]
CMD ["app.py"]
