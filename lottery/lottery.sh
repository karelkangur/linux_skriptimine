#!/bin/bash

# Loto mängu põhiprogramm

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PLAYER_FILE="$SCRIPT_DIR/player_numbers.txt"
LOTTERY_FILE="$SCRIPT_DIR/lottery_numbers.txt"
RESULTS_FILE="$SCRIPT_DIR/results.txt"

PLAYER_NAME=""
MATCHES=0
RESULT=""

source "$SCRIPT_DIR/input.sh"
source "$SCRIPT_DIR/lottery_functions.sh"
source "$SCRIPT_DIR/result.sh"
source "$SCRIPT_DIR/files.sh"

show_header
clear_files "$PLAYER_FILE" "$LOTTERY_FILE"

read_player
read_player_numbers "$PLAYER_FILE"
show_player_numbers "$PLAYER_FILE"

generate_lottery_numbers "$LOTTERY_FILE"
show_lottery_numbers "$LOTTERY_FILE"

check_matches "$PLAYER_FILE" "$LOTTERY_FILE"
set_result "$MATCHES"
show_result "$PLAYER_NAME" "$MATCHES" "$RESULT"

save_result \
    "$RESULTS_FILE" \
    "$PLAYER_FILE" \
    "$LOTTERY_FILE" \
    "$PLAYER_NAME" \
    "$MATCHES" \
    "$RESULT"
