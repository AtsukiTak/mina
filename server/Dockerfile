FROM gcr.io/mina-295407/mina-backend-builder as builder

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /home/builder/mina-app .
ENTRYPOINT ["./mina-app"]
