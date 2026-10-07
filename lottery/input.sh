# Kasutaja sisendi funktsioonid

read_player() {
    read -p "Sisesta mängija nimi: " PLAYER_NAME

    if [ -z "$PLAYER_NAME" ]; then
        PLAYER_NAME="Unknown"
    fi
}

validate_number() {
    local number="$1"
    local file="$2"

    if [ -z "$number" ]; then
        echo "Viga: number jäi sisestamata."
        return 1
    fi

    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
        echo "Viga: sisesta täisarv."
        return 1
    fi

    if [ "$number" -lt 1 ] || [ "$number" -gt 50 ]; then
        echo "Viga: number peab olema vahemikus 1-50."
        return 1
    fi

    if grep -qx "$number" "$file"; then
        echo "Viga: number $number on juba valitud."
        return 1
    fi

    return 0
}

read_player_numbers() {
    local file="$1"
    local count=0
    local number

    echo
    echo "Sisesta 5 erinevat numbrit vahemikus 1-50."
    echo

    while [ "$count" -lt 5 ]; do
        read -p "Sisesta number $((count + 1)): " number

        if validate_number "$number" "$file"; then
            echo "$number" >> "$file"
            count=$((count + 1))
        fi
    done
}

show_player_numbers() {
    local file="$1"

    echo
    echo "Mängija valitud numbrid:"
    cat "$file"
}
