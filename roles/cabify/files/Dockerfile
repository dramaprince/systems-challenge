FROM alpine:3.7
LABEL maintainer "David Gonzalez <estromboliano@gmail.com>"

RUN apk add --no-cache curl python py-pip \
    && pip install --upgrade pip \
    && pip install bottle 

RUN adduser -u 1000 -D -S cabify

COPY entrypoint.sh cabify.py payload.json /home/cabify/

USER cabify 

WORKDIR /home/cabify

EXPOSE 8181

ENTRYPOINT ["/home/cabify/entrypoint.sh"]
