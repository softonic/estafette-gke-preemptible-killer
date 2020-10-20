FROM golang:1.14-buster AS build

ENV GOBIN=$GOPATH/bin

ENV CGO_ENABLED="0" \
    GOOS="linux"

ADD . /src/estafette-gke-preemptible-killer

WORKDIR /src/estafette-gke-preemptible-killer

RUN apt-get update -qqq \
    && apt-get install -y ca-certificates 
RUN update-ca-certificates

RUN make build

FROM debian:buster-slim

LABEL maintainer="estafette.io" \
      description="The estafette-gke-preemptible-killer component is a Kubernetes controller that ensures preemptible nodes in a Container Engine cluster don't expire at the same time"

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /src/estafette-gke-preemptible-killer/estafette-gke-preemptible-killer /estafette-gke-preemptible-killer

ENTRYPOINT ["/estafette-gke-preemptible-killer"]

