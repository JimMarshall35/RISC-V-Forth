FROM alpine:latest 
RUN apk update
RUN apk add --no-cache bash
RUN apk add python3
RUN apk add python3 py3-pip
RUN mkdir /src/
COPY ./bootloader.py /src/bootloader.py
COPY ./autoflash.sh /src/autoflash.sh
COPY ./wchisp-linux-aarch64/wchisp /src/wchisp
WORKDIR /src
RUN python3 -m venv .venv
RUN . ./.venv/bin/activate && pip install pytest RPi.GPIO pexpect
RUN echo "source .venv/bin/activate" >> ~/.bashrc
ENV PATH="/src/:${PATH}"
# run with these opitons --device=/dev/gpiomem --device=/dev/gpiochip0 --device=/dev/ttyUSB0 --group-add keep-groups --privileged

