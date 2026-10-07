# Failidega seotud funktsioonid

clear_files() {
    local player_file="$1"
    local lottery_file="$2"

    > "$player_file"
    > "$lottery_file"
}

save_result() {
    local results_file="$1"
    local player_file="$2"
    local lottery_file="$3"
    local player="$4"
    local matches="$5"
    local result="$6"

    {
        echo "========================================"
        echo "Date: $(date)"
        echo "Player: $player"
        echo "Player numbers:"
        cat "$player_file"
        echo "Lottery numbers:"
        cat "$lottery_file"
        echo "Matches: $matches"
        echo "Result: $result"
    } >> "$results_file"

    echo
    echo "Tulemus salvestati faili $results_file."
}
