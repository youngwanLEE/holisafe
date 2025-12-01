#!/bin/bash

# --------------------------------------------------------------------------------
# HoliSafe: Holistic Safety Benchmarking and Modeling for Vision-Language Model
# Copyright (c) 2025 Electronics and Telecommunications Research Institute (ETRI).
# All Rights Reserved.
# Written by Youngwan Lee
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
# --------------------------------------------------------------------------------


# Exit on any error
set -e

# Check if all required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Error: Insufficient arguments."
    echo "Usage: $0 <input_json_file> <data_dir_prefix> [gemini_model] [max_concurrent] [batch_size]"
    echo ""
    echo "Example: $0 checkpoints/results/model_holisafe_bench_cleaned.json '/Data3/data/holisafe_bench' 'gemini-2.0-flash' 10 100"
    echo ""
    echo "Arguments:"
    echo "  input_json_file    - Path to JSON file with predictions (required)"
    echo "  data_dir_prefix    - Image directory prefix (required)"
    echo "  gemini_model       - Gemini model to use (default: gemini-2.0-flash)"
    echo "  max_concurrent     - Maximum concurrent requests (default: 10)"
    echo "  batch_size         - Number of items per batch (default: 100)"
    echo ""
    echo "This script evaluates model predictions using Gemini Batch API (v2 - for cleaned JSON format)."
    echo "It expects JSON with 'query' field directly available (not in 'conversations')."
    exit 1
fi

INPUT_FILE=$1

# Get the directory of the input file for output
OUTPUT_DIR=$(dirname "$INPUT_FILE")

PYTHON_SCRIPT_ARGS=""

# Required data_dir_prefix (2nd arg)
if [ -n "$2" ]; then
    PYTHON_SCRIPT_ARGS+=" --data_dir_prefix $2"
    echo "Setting data_dir_prefix: $2"
else
    echo "Error: data_dir_prefix argument is required."
    exit 1
fi

# Optional Gemini model (3rd arg)
if [ -n "$3" ]; then
    PYTHON_SCRIPT_ARGS+=" --gemini_model $3"
    echo "Using Gemini model: $3"
else
    echo "Using default Gemini model: gemini-2.0-flash"
fi

# Optional max_concurrent (4th arg)
if [ -n "$4" ]; then
    PYTHON_SCRIPT_ARGS+=" --max_concurrent $4"
    echo "Setting max_concurrent: $4"
else
    echo "Using default max_concurrent: 10"
fi

# Optional batch_size (5th arg)
if [ -n "$5" ]; then
    PYTHON_SCRIPT_ARGS+=" --batch_size $5"
    echo "Setting batch_size: $5"
else
    echo "Using default batch_size: 100"
fi

# Validate input file path
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input JSON file does not exist: $INPUT_FILE"
    exit 1
fi

# Define log file path within the output directory
SHELL_LOG_FILE="$OUTPUT_DIR/eval_by_gemini_batch_v2_run_$(date +%Y%m%d_%H%M%S).log"

echo "=========================================="
echo "Gemini Batch Evaluation Script (v2)"
echo "=========================================="
echo "Input file: $INPUT_FILE"
echo "Output directory: $OUTPUT_DIR"
if [ -n "$PYTHON_SCRIPT_ARGS" ]; then
    echo "Additional arguments: $PYTHON_SCRIPT_ARGS"
fi
echo "Shell log: $SHELL_LOG_FILE"
echo "=========================================="

# Ensure GOOGLE_API_KEY is available
if [ -z "$GOOGLE_API_KEY" ]; then
    echo "Warning: GOOGLE_API_KEY environment variable is not set."
    echo "The script will fail unless the key is provided via --google_api_key argument."
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_SCRIPT_PATH="$SCRIPT_DIR/eval_by_gemini_batch_v2.py"

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then
    echo "Error: Python script not found: $PYTHON_SCRIPT_PATH"
    exit 1
fi

# Run the Python script, tee output to log file and console
COMMAND="python \"$PYTHON_SCRIPT_PATH\" --input_file \"$INPUT_FILE\" --output_dir \"$OUTPUT_DIR\" $PYTHON_SCRIPT_ARGS"
echo "Executing: $COMMAND"
echo ""

if eval "$COMMAND" 2>&1 | tee "$SHELL_LOG_FILE"; then
    echo ""
    echo "=========================================="
    echo "Evaluation completed successfully!"
    echo "=========================================="
    echo "Results directory: $OUTPUT_DIR"
    echo "Shell log: $SHELL_LOG_FILE"
    echo ""
    echo "Output files:"
    echo "  - *_eval_by_gemini_results.json (scored predictions)"
    echo "  - *_eval_by_gemini_metrics_summary.txt (human-readable metrics)"
    echo "  - *_eval_by_gemini_ordered_metrics.txt (comma-separated values)"
    echo "  - *.log (detailed Python script log)"
else
    echo ""
    echo "=========================================="
    echo "Error: Evaluation failed!"
    echo "=========================================="
    echo "Check logs:"
    echo "  - Shell log: $SHELL_LOG_FILE"
    echo "  - Python logs in: $OUTPUT_DIR/*.log"
    exit 1
fi

echo "Gemini batch evaluation script (v2) finished."
