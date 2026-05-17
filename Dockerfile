FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    curl \
    make \
    bash \
    tar \
    python3 \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/src

RUN curl -L -o /tmp/src/toolchain.tar.gz \
    https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v15.2.0-1/xpack-riscv-none-elf-gcc-15.2.0-1-linux-x64.tar.gz

RUN curl -L -o /tmp/src/toolchain.sha \
    https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v15.2.0-1/xpack-riscv-none-elf-gcc-15.2.0-1-linux-x64.tar.gz.sha

RUN echo "$(sha256sum /tmp/src/toolchain.tar.gz)"
RUN echo "$(cat /tmp/src/toolchansha.sha)"

RUN mkdir -p /opt/toolchain \
 && tar -xzf /tmp/src/toolchain.tar.gz -C /opt/toolchain --strip-components=1

RUN rm -rf /tmp/src

ENV PATH="/opt/toolchain/bin:${PATH}"