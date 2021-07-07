ARG NODE_VERSION="12"

FROM nodered/node-red:1.3.5-${NODE_VERSION}

USER root
RUN apk update && apk add python3-dev
USER node-red

COPY ./data /data
WORKDIR /usr/src/node-red
RUN npm install node-red-contrib-azure-iot-edge-module && \
    pip3 install --upgrade pip && pip3 install sparkfun-ublox-gps pyserial spidev

EXPOSE 1880/tcp

ENTRYPOINT ["npm", "--no-update-notifier", "--no-fund", "start", "--cache", "/data/.npm", "--", "--userDir", "/data", "/data/flows.json"]
