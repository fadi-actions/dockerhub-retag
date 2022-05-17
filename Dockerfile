FROM alpine:3.15.4

ADD entrypoint.sh /
RUN chmod 0755 /entrypoint.sh
RUN apk add --no-cache curl jq

ENTRYPOINT ["/entrypoint.sh"]
