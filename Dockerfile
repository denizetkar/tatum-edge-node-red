ARG ARCH="amd64"
ARG NODE_VERSION="12"

FROM nodered/node-red:1.3.5-${NODE_VERSION}-${ARCH}

USER node-red

COPY ./data /data
RUN npm install node-red-contrib-azure-iot-edge-module

EXPOSE 1880/tcp

ENTRYPOINT ["npm", "--no-update-notifier", "--no-fund", "start", "--cache", "/data/.npm", "--", "--userDir", "/data", "/data/flows.json"]
