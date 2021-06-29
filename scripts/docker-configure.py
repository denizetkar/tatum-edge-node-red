import argparse
import json
import os
from typing import Any, Dict


def main(args: argparse.Namespace):
    docker_daemon_path = "/etc/docker/daemon.json"
    config: Dict[str, Any] = {}
    if os.path.isfile(docker_daemon_path):
        with open(docker_daemon_path, "rt") as f:
            config = json.load(f)
    config["log-driver"] = "json-file"
    config["log-opts"] = {"max-size": "10m", "max-file": "3"}
    config["dns"] = ["8.8.8.8", "8.8.4.4"]
    with open(docker_daemon_path, "wt") as f:
        json.dump(config, f, default=str, indent=2)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    main(parser.parse_args())
