#!/bin/bash

# Define the base directory
BASE_DIR="/root/arpansahu-one-scripts"

# Define the virtual environment directory
VENV_DIR="$BASE_DIR/venv"

# Define the requirements file
REQUIREMENTS_FILE="$BASE_DIR/requirements.txt"

# Define the Python script to run
PYTHON_SCRIPT="$BASE_DIR/website_up_time.py"

# Load environment variables from .env file if it exists
if [ -f "$BASE_DIR/.env" ]; then
    echo "Loading environment variables from .env file..."
    source "$BASE_DIR/.env"
fi

# Check if virtual environment directory exists
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists."
else
    # Create a virtual environment
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR" || { echo "Failed to create virtual environment."; exit 1; }
fi

# Activate the virtual environment
echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate" || { echo "Failed to activate virtual environment."; exit 1; }

# Upgrade pip in the virtual environment
echo "Upgrading pip..."
pip install --upgrade pip || { echo "Failed to upgrade pip."; exit 1; }

# Install requirements
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Installing dependencies..."
    pip install -r "$REQUIREMENTS_FILE" || { echo "Failed to install dependencies."; exit 1; }
else
    echo "Requirements file not found at $REQUIREMENTS_FILE. Skipping dependency installation."
fi

# Run the Python script
if [ -f "$PYTHON_SCRIPT" ]; then
    echo "Running the Python script..."
    python "$PYTHON_SCRIPT" || { echo "Failed to run the Python script."; exit 1; }
else
    echo "Python script not found at $PYTHON_SCRIPT. Exiting."
    exit 1
fi

# Deactivate the virtual environment
echo "Deactivating virtual environment..."
deactivate

# Remove the virtual environment directory
echo "Deleting virtual environment..."
rm -rf "$VENV_DIR" || { echo "Failed to delete virtual environment."; exit 1; }

echo "Done."