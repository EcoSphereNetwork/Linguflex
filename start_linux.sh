#!/bin/bash

# Activate virtual environment
source venv/bin/activate

# Set environment variables
export PYTHONPATH=$PYTHONPATH:$(pwd)
export QT_QPA_PLATFORM=xcb

# Start Linguflex
echo "Starting Linguflex..."
python3 -m lingu.core.run 2>&1 | tee logs/linguflex.log