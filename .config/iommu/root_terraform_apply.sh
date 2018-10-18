#!/bin/bash

set -xeuo pipefail

export TF_VAR_root_write="false"
terraform plan

export TF_VAR_root_write="true"
terraform apply

