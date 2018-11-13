FROM ubuntu:latest

# ENV http_proxy http://cache.ha.univ-nantes.fr:3128
# ENV https_proxy http://cache.ha.univ-nantes.fr:3128

MAINTAINER Sylvain DAVID "sylvain.david@rozofs.com"

RUN apt-get update -y && apt-get install -y python-pip python-dev build-essential
COPY ./app /app
WORKDIR /app
RUN pip install -r requirements.txt
ENTRYPOINT ["python"]
CMD ["app.py"]