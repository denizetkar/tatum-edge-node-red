# TaTUM Edge Node RED project
This project implements a docker image that contains **Node RED** which was meant to be run only in an Azure IoT Edge runtime. Inside the Node RED, some telemetry data is collected and sent off to the Azure IotHub. The node in Node RED that sends this data has to be properly configured with credentials.

* Node RED will listen on `NODERED_HOST_PORT` port, which is `1880` by default. You can change in in `.env` file.
* However, this docker image was not meant for interactive use via web interface because any changes you make in the deployed container will be deleted when the container is deleted.
* In order to make changes in the docker image, change contents of the `data` folder before building the image and deploying it.

## Usage
* Install latest version of **Docker**,
* Run `build-and-push-image.ps1` with its command line arguments to build the docker image and push it to an image repository to which you must be logged in beforehand using `docker login <image-repo-url>`,
* Using **Azure Portal** or your own deployment manifest, deploy the image as an edge module to the IoT edge device(s).
