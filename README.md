# TaTUM Edge Node RED project
This project implements a docker image that contains **Node RED** which was meant to be run only in an Azure IoT Edge runtime. Inside the Node RED, some telemetry data is collected and sent off to the Azure IotHub. The node in Node RED that sends this data has to be properly configured with credentials.

* Node RED will listen on `NODERED_HOST_PORT` port, which is `1880` by default. You can change in in `.env` file.
* However, this docker image was not meant for interactive use via web interface because any changes you make in the deployed container will be deleted when the container is deleted.
* In order to make changes in the docker image, change contents of the `data` folder before building the image and deploying it.

## Dependencies
* To build and push the container image:
  * Latest Docker (>= 20.10.6), see [HERE](https://docs.docker.com/get-docker/) for details.
  * Latest Powershell (>=7.1.3), see [HERE](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.1) for details.
* To deploy Azure IoT edge runtime into the IoT device:
  * A linux device, see [HERE](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge?view=iotedge-2018-06#prerequisites) for detailed prerequisites.
  * A `bash` shell,
  * `python3` must be installed (Python 3.7+),
  * Azure CLI, see [HERE](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) for more details.
* To deploy the image into an IoT edge device:
  * A `bash` shell,
  * Azure CLI, see [HERE](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) for more details.

## Usage
* To build and push the container image:
  * Open a **powershell** terminal in the project root folder,
  * Run `docker login <image-repo-url>` to login to the image repository,
  * Run `build-and-push-image.ps1` with its command line arguments.
* To deploy Azure IoT edge runtime into the IoT device:
  * Open a **bash** terminal in the project root folder,
  * Run `sudo ./scripts/deploy-iot-edge.sh [EDGE_DEVICE_CONN_STR]`,
    * `[EDGE_DEVICE_CONN_STR]` is the connection string of the edge device in which we are deploying IoT Edge runtime,
  * See [HERE](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge?view=iotedge-2018-06) for more details.
* To deploy the image into an IoT edge device:
  * In the file `manifests/deployment.json`,
    * Replace `PRIVATE_IMAGE_REGISTRY_HOST` with the image registry url,
    * Replace `PRIVATE_IMAGE_REGISTRY_USERNAME` with the username,
    * Replace `PRIVATE_IMAGE_REGISTRY_PASSWORD` with the password.
  * Open a terminal in the project root folder,
  * Run `az account list -o table` to check if you are already logged into your Azure account. If a warning appears, run `az login` to login,
  * Open a **bash** terminal in the project root folder,
  * Run `sudo ./scripts/deploy-manifest.sh [DEVICE_ID] [HUB_NAME] [MANIFEST_PATH]` where:
    * `[DEVICE_ID]` is the device id of the edge device,
    * `[HUB_NAME]` is the name of the Azure IoTHub service,
    * `[MANIFEST_PATH]` is the relative path to the deployment manifest json file such as `./manifests/deployment.json`.
  * See [HERE](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-deploy-modules-cli?view=iotedge-2018-06) for more details.
