#!/bin/bash

# Define the virtual environment directory
VENV_DIR="venv"

# Define the requirements file
REQUIREMENTS_FILE="requirements.txt"

# Define the Python script to run
PYTHON_SCRIPT="website_up_time.py"

# Check if virtual environment directory exists
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists."
else
    # Create a virtual environment
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Upgrade pip in the virtual environment
echo "Upgrading pip..."
pip install --upgrade pip

# Install requirements
if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "Installing dependencies..."
    pip install -r "$REQUIREMENTS_FILE"
else
    echo "Requirements file not found. Skipping dependency installation."
fi

# Run the Python script
if [ -f "$PYTHON_SCRIPT" ]; then
    echo "Running the Python script..."
    python "$PYTHON_SCRIPT"
else
    echo "Python script not found. Exiting."
fi

# Deactivate the virtual environment
deactivate

# Remove the virtual environment directory
echo "Deleting virtual environment..."
rm -rf "$VENV_DIR"

echo "Done."