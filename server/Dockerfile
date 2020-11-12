FROM ekidd/rust-musl-builder:1.47.0 as backend-builder
WORKDIR /home/rust/src
COPY . .
RUN cargo build --release -p mina-app

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=backend-builder /home/rust/src/target/x86_64-unknown-linux-musl/release/mina-app ./
ENTRYPOINT ["./mina-app"]
