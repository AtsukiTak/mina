FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY ./musl-build/mina-app ./
ENTRYPOINT ["./mina-app"]
