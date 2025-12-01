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
    echo "Usage: $0 <input_json_file> <data_dir_prefix> [openai_model] [max_concurrent] [requests_per_minute] [retry_count]"
    echo ""
    echo "Example: $0 checkpoints/results/model_holisafe_bench_cleaned.json '/Data3/data/holisafe_bench' 'gpt-4o' 10 500 3"
    echo ""
    echo "Arguments:"
    echo "  input_json_file        - Path to JSON file with predictions (required)"
    echo "  data_dir_prefix        - Image directory prefix (required)"
    echo "  openai_model           - OpenAI model to use (default: gpt-4o)"
    echo "  max_concurrent         - Maximum concurrent requests (default: 10)"
    echo "  requests_per_minute    - Maximum requests per minute (default: 500)"
    echo "  retry_count            - Number of retries for failed requests (default: 3)"
    echo ""
    echo "This script evaluates model predictions using OpenAI Parallel API (v2 - for cleaned JSON format)."
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

# Optional OpenAI model (3rd arg)
if [ -n "$3" ]; then
    PYTHON_SCRIPT_ARGS+=" --openai_model $3"
    echo "Using OpenAI model: $3"
else
    echo "Using default OpenAI model: gpt-4o"
fi

# Optional max_concurrent (4th arg)
if [ -n "$4" ]; then
    PYTHON_SCRIPT_ARGS+=" --max_concurrent $4"
    echo "Setting max_concurrent: $4"
else
    echo "Using default max_concurrent: 10"
fi

# Optional requests_per_minute (5th arg)
if [ -n "$5" ]; then
    PYTHON_SCRIPT_ARGS+=" --requests_per_minute $5"
    echo "Setting requests_per_minute: $5"
else
    echo "Using default requests_per_minute: 500"
fi

# Optional retry_count (6th arg)
if [ -n "$6" ]; then
    PYTHON_SCRIPT_ARGS+=" --retry_count $6"
    echo "Setting retry_count: $6"
else
    echo "Using default retry_count: 3"
fi

# Validate input file path
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input JSON file does not exist: $INPUT_FILE"
    exit 1
fi

# Define log file path within the output directory
SHELL_LOG_FILE="$OUTPUT_DIR/eval_by_openai_parallel_v2_run_$(date +%Y%m%d_%H%M%S).log"

echo "=========================================="
echo "OpenAI Parallel Evaluation Script (v2)"
echo "=========================================="
echo "Input file: $INPUT_FILE"
echo "Output directory: $OUTPUT_DIR"
if [ -n "$PYTHON_SCRIPT_ARGS" ]; then
    echo "Additional arguments: $PYTHON_SCRIPT_ARGS"
fi
echo "Shell log: $SHELL_LOG_FILE"
echo "=========================================="

# Ensure OPENAI_API_KEY is available
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Warning: OPENAI_API_KEY environment variable is not set."
    echo "The script will fail unless the key is provided via --openai_api_key argument."
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_SCRIPT_PATH="$SCRIPT_DIR/eval_by_openai_parallel_v2.py"

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
    echo "  - *_eval_by_openai_results.json (scored predictions)"
    echo "  - *_eval_by_openai_metrics_summary.txt (human-readable metrics)"
    echo "  - *_eval_by_openai_ordered_metrics.txt (comma-separated values)"
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

echo "OpenAI parallel evaluation script (v2) finished."
