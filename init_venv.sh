#!/usr/bin/env bash

# Initialize a Python virtual environment and install necessary packages

set -e

if [ -d ".venv" ]; then
  echo ".venv already exists. Skipping virtual environment setup."
  exit 0
fi

python3 -m venv .venv
source .venv/bin/activate

pip install -U jupyter notebook
