FROM python:2.7-alpine3.6
LABEL maintainer "David Gonzalez <estromboliano@gmail.com>"

RUN pip install bottle consulate

RUN adduser -u 1000 -D -S cabify

COPY entrypoint.sh cabify.py /home/cabify/

USER cabify 

WORKDIR /home/cabify

EXPOSE 8181

ENTRYPOINT ["/home/cabify/entrypoint.sh"]
