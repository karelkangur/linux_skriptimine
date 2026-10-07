#!/bin/bash

# Lihtne lotomäng funktsioonidega

PLAYER_FILE="player_numbers.txt"
LOTTERY_FILE="lottery_numbers.txt"
RESULTS_FILE="results.txt"

player_name=""
matches=0
result=""

show_header() {
    echo "=============================="
    echo "          LOTO MÄNG"
    echo "=============================="
    echo
}

clear_files() {
    > "$PLAYER_FILE"
    > "$LOTTERY_FILE"
}

read_player() {
    read -p "Sisesta mängija nimi: " player_name

    if [ -z "$player_name" ]; then
        player_name="Unknown"
    fi
}

read_player_numbers() {
    local count=0
    local number

    echo
    echo "Sisesta 5 erinevat numbrit vahemikus 1-50."
    echo

    while [ "$count" -lt 5 ]; do

        read -p "Sisesta number $((count + 1)): " number

        if [ -z "$number" ]; then
            echo "Viga: number jäi sisestamata."
            continue
        fi

        if ! [[ "$number" =~ ^[0-9]+$ ]]; then
            echo "Viga: sisesta täisarv."
            continue
        fi

        if [ "$number" -lt 1 ] || [ "$number" -gt 50 ]; then
            echo "Viga: number peab olema vahemikus 1-50."
            continue
        fi

        if grep -qx "$number" "$PLAYER_FILE"; then
            echo "Viga: number $number on juba valitud."
            continue
        fi

        echo "$number" >> "$PLAYER_FILE"
        count=$((count + 1))

    done
}

show_player_numbers() {
    echo
    echo "Mängija valitud numbrid:"
    cat "$PLAYER_FILE"
}

generate_lottery_numbers() {
    local count=0
    local lottery_number

    while [ "$count" -lt 5 ]; do

        lottery_number=$((RANDOM % 50 + 1))

        if grep -qx "$lottery_number" "$LOTTERY_FILE"; then
            continue
        fi

        echo "$lottery_number" >> "$LOTTERY_FILE"
        count=$((count + 1))

    done
}

show_lottery_numbers() {
    echo
    echo "Võidunumbrid:"
    cat "$LOTTERY_FILE"
}

check_matches() {
    local number

    matches=0

    echo
    echo "Tulemuste kontroll:"
    echo

    while read -r number; do

        echo "Kontrollin numbrit $number..."

        if grep -qx "$number" "$LOTTERY_FILE"; then
            echo "TABAMUS!"
            matches=$((matches + 1))
        else
            echo "Ei tabanud."
        fi

        echo

    done < "$PLAYER_FILE"
}

set_result() {
    case $matches in
        5)
            result="JACKPOT!"
            ;;
        4)
            result="Väga hea tulemus!"
            ;;
        3)
            result="Hea tulemus."
            ;;
        2)
            result="Kaks tabamust."
            ;;
        1)
            result="Üks tabamus."
            ;;
        0)
            result="Seekord tabamusi ei olnud."
            ;;
    esac
}

show_result() {
    echo "Mängija: $player_name"
    echo "Tabamusi: $matches / 5"
    echo "$result"
}

save_result() {
    {
        echo "========================================"
        echo "Date: $(date)"
        echo "Player: $player_name"
        echo "Player numbers:"
        cat "$PLAYER_FILE"
        echo "Lottery numbers:"
        cat "$LOTTERY_FILE"
        echo "Matches: $matches"
        echo "Result: $result"
    } >> "$RESULTS_FILE"

    echo
    echo "Tulemus salvestati faili $RESULTS_FILE."
}

# Programmi põhiosa

show_header
clear_files
read_player
read_player_numbers
show_player_numbers
generate_lottery_numbers
show_lottery_numbers
check_matches
set_result
show_result
save_result
