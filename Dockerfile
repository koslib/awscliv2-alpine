ARG ALPINE_VERSION=3.16

FROM python:3.10.8-alpine${ALPINE_VERSION} as builder

# Install build dependencies
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake

# Clone awscli
ARG AWS_CLI_VERSION=2.7.20
RUN git clone https://github.com/aws/aws-cli.git --single-branch -b ${AWS_CLI_VERSION} awscli

# Build process
WORKDIR awscli
RUN sed -i'' 's/PyInstaller.*/PyInstaller==5.2/g' requirements-build.txt
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

# Remove examples as unnecessary
RUN rm -rf /usr/local/aws-cli/v2/current/dist/awscli/examples
RUN find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

# Copy to the final image the executables
FROM alpine:${ALPINE_VERSION}
COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /aws-cli-bin/ /usr/local/bin/