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
  * Internet connection,
  * Root permissions,
  * `python3` must be installed (Python 3.7+),
  * Azure CLI, see [HERE](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) for more details.

## Usage
* To build and push the container image:
  * Open a **powershell** terminal in the project root folder,
  * Run `build-and-push-image.ps1` with its command line arguments to build the docker image and push it to an image repository to which you must be logged in beforehand using `docker login <image-repo-url>`.
* To deploy Azure IoT edge runtime into the IoT device:
  * Open a **bash** terminal in `scripts` folder or `cd scripts` into the folder,
  * Run `sudo ./deploy-iot-edge.sh`,
  * In `config.yaml` file, uncomment the following lines:
    ```yaml
    provisioning:
    source: "manual"
    device_connection_string: ""
    dynamic_reprovisioning: false
    ```
  * Paste the device connection string of the edge device to the corresponding field: `device_connection_string`,
  * Manually run the paragraph of commands that follow the last uncommented command, in `deploy-iot-edge.sh` at line 48, 49 and 51 in order to:
    * Copy `config.yaml` back to where it belongs,
    * Change the owner of the file to `iotedge` user and group,
    * Restart the `iotedge` linux service to load the configuration.
  * See [HERE](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge?view=iotedge-2018-06) for more details.
* To deploy the image into an IoT edge device:
  * In the file `manifests/deployment.json`,
    * Replace `PRIVATE_IMAGE_REGISTRY_HOST` with the image registry url,
    * Replace `PRIVATE_IMAGE_REGISTRY_USERNAME` with the username,
    * Replace `PRIVATE_IMAGE_REGISTRY_PASSWORD` with the password.
  * Open a terminal in the project root folder,
  * Run `az account list -o table` to check if you are already logged into your Azure account. If a warning appears, run `az login` to login,
  * Run `az iot edge set-modules --device-id [device id] --hub-name [hub name] --content [file path]` where:
    * `[device id]` is the device id of the edge device,
    * `[hub name]` is the name of the Azure IoTHub service,
    * `[file path]` is the relative path to the deployment manifest json file such as `./manifests/deployment.json`.
    * See [HERE](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-deploy-modules-cli?view=iotedge-2018-06) for more details.
