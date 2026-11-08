FROM syncthing/syncthing:2.1.7@sha256:2b71da7c0d0a91a6ae5285ad079226fecc0a365d08b27720e1f7037b018f7546 AS donor

FROM golang:1.27.3-alpine3.24@sha256:d200d2dd76b03a99b52651fd1325aff7dcd35422c35c01bac56571b0507f3deb AS go-builder

WORKDIR /build

COPY go.mod ./
COPY probe/ ./probe/

RUN mkdir -p /out/var/syncthing/config /out/data /out/tmp /out/etc/ssl/certs && \
    chmod 0755 /out/var /out/var/syncthing /out/etc /out/etc/ssl /out/etc/ssl/certs && \
    chmod 0700 /out/var/syncthing/config /out/data && \
    chmod 1777 /out/tmp && \
    cp /etc/ssl/certs/ca-certificates.crt /out/etc/ssl/certs/ca-certificates.crt && \
    chmod 0444 /out/etc/ssl/certs/ca-certificates.crt && \
    CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o /out/probe ./probe

FROM scratch

ENV HOME=/var/syncthing \
    STGUIADDRESS=0.0.0.0:8384 \
    STHOMEDIR=/var/syncthing/config \
    STNOUPGRADE=1

COPY --from=go-builder /out/etc /etc
COPY --from=go-builder /out/var /var
COPY --from=go-builder /out/data /data
COPY --from=go-builder /out/tmp /tmp
COPY --from=donor --chmod=0555 /bin/syncthing /usr/local/bin/syncthing
COPY --from=go-builder --chmod=0555 /out/probe /usr/local/bin/probe

ENTRYPOINT ["/usr/local/bin/syncthing"]
