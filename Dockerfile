ARG NODE_VERSION="12"

FROM nodered/node-red:1.3.5-${NODE_VERSION}

USER node-red

COPY ./data /data
WORKDIR /usr/src/node-red
RUN npm install node-red-contrib-azure-iot-edge-module

EXPOSE 1880/tcp

USER root
ENTRYPOINT ["npm", "--no-update-notifier", "--no-fund", "start", "--cache", "/data/.npm", "--", "--userDir", "/data", "/data/flows.json"]
