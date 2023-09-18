FROM golang:1.19-alpine AS gobuild

WORKDIR /build
ADD go.mod go.sum /build/
RUN go mod download -x
ADD cmd /build/cmd
ADD pkg /build/pkg
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver

RUN ([ "$(arch)" == "aarch64" ] && ARCH=arm64) || ARCH=amd64; \
    wget -O /tmp/geesefs "https://github.com/yandex-cloud/geesefs/releases/latest/download/geesefs-linux-$ARCH"

FROM alpine:3.17
LABEL maintainers="Vitaliy Filippov <vitalif@yourcmc.ru>"
LABEL description="csi-s3 slim image"

RUN apk add --no-cache fuse mailcap rclone
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/community s3fs-fuse

COPY --chown=755 --from=gobuild /tmp/geesefs /usr/bin/geesefs

COPY --from=gobuild /build/s3driver /s3driver
ENTRYPOINT ["/s3driver"]
