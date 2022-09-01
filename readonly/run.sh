#!/bin/bash

firecracker --api-sock /tmp/firecracker.socket --config-file multi-disk.json && rm -f /tmp/firecracker.socket