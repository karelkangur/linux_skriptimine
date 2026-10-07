# Lotonumbrite genereerimise funktsioonid

generate_lottery_numbers() {
    local file="$1"
    local count=0
    local number

    while [ "$count" -lt 5 ]; do
        number=$((RANDOM % 50 + 1))

        if grep -qx "$number" "$file"; then
            continue
        fi

        echo "$number" >> "$file"
        count=$((count + 1))
    done
}

show_lottery_numbers() {
    local file="$1"

    echo
    echo "Võidunumbrid:"
    cat "$file"
}
