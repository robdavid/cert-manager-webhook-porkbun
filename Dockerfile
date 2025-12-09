FROM golang:1.25-alpine3.23 AS build_deps

RUN apk add --no-cache --update ca-certificates git tzdata

WORKDIR /workspace

COPY go.mod .
COPY go.sum .

RUN go mod download

FROM build_deps AS build

COPY . .

RUN CGO_ENABLED=0 go build -o webhook -ldflags '-w -extldflags "-static"' .

FROM scratch

COPY --from=build_deps /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build_deps /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build /workspace/webhook /webhook

ENTRYPOINT ["/webhook"]
