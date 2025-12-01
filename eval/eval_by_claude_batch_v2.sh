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
    echo "Usage: $0 <input_json_file> <data_dir_prefix> [claude_model] [max_requests_per_batch] [polling_interval]"
    echo ""
    echo "Example: $0 checkpoints/results/model_holisafe_bench_cleaned.json '/Data3/data/holisafe_bench' 'claude-sonnet-4-5-20250929' 10000 60"
    echo ""
    echo "Arguments:"
    echo "  input_json_file        - Path to JSON file with predictions (required)"
    echo "  data_dir_prefix        - Image directory prefix (required)"
    echo "  claude_model           - Claude model to use (default: claude-sonnet-4-5-20250929)"
    echo "  max_requests_per_batch - Max requests per batch (default: 10000)"
    echo "  polling_interval       - Polling interval in seconds (default: 60)"
    echo ""
    echo "IMPORTANT NOTE: claude-3-5-sonnet-20241022 is DEPRECATED and no longer works!"
    echo "  - Use: claude-sonnet-4-5-20250929 (default)"
    echo "  - Or:  claude-sonnet-4-20250514"
    echo ""
    echo "This script evaluates model predictions using Claude Batch API (v2 - for cleaned JSON format)."
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

# Optional Claude model (3rd arg)
if [ -n "$3" ]; then
    PYTHON_SCRIPT_ARGS+=" --claude_model $3"
    echo "Using Claude model: $3"
else
    echo "Using default Claude model: claude-sonnet-4-5-20250929"
fi

# Optional max_requests_per_batch (4th arg)
if [ -n "$4" ]; then
    PYTHON_SCRIPT_ARGS+=" --max_requests_per_batch $4"
    echo "Setting max_requests_per_batch: $4"
else
    echo "Using default max_requests_per_batch: 10000"
fi

# Optional polling_interval (5th arg)
if [ -n "$5" ]; then
    PYTHON_SCRIPT_ARGS+=" --polling_interval $5"
    echo "Setting polling_interval: $5 seconds"
else
    echo "Using default polling_interval: 60 seconds"
fi

# Validate input file path
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input JSON file does not exist: $INPUT_FILE"
    exit 1
fi

# Define log file path within the output directory
SHELL_LOG_FILE="$OUTPUT_DIR/eval_by_claude_batch_v2_run_$(date +%Y%m%d_%H%M%S).log"

echo "=========================================="
echo "Claude Batch Evaluation Script (v2)"
echo "=========================================="
echo "Input file: $INPUT_FILE"
echo "Output directory: $OUTPUT_DIR"
if [ -n "$PYTHON_SCRIPT_ARGS" ]; then
    echo "Additional arguments: $PYTHON_SCRIPT_ARGS"
fi
echo "Shell log: $SHELL_LOG_FILE"
echo "=========================================="

# Ensure ANTHROPIC_API_KEY is available
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Warning: ANTHROPIC_API_KEY environment variable is not set."
    echo "The script will fail unless the key is provided via --anthropic_api_key argument."
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_SCRIPT_PATH="$SCRIPT_DIR/eval_by_claude_batch_v2.py"

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
    echo "  - *_eval_by_claude_results.json (scored predictions)"
    echo "  - *_eval_by_claude_metrics_summary.txt (human-readable metrics)"
    echo "  - *_eval_by_claude_ordered_metrics.txt (comma-separated values)"
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

echo "Batch evaluation script finished."
