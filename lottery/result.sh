# Tulemuste kontrollimise ja kuvamise funktsioonid

show_header() {
    echo "=============================="
    echo "          LOTO MÄNG"
    echo "=============================="
    echo
}

check_matches() {
    local player_file="$1"
    local lottery_file="$2"
    local number

    MATCHES=0

    echo
    echo "Tulemuste kontroll:"
    echo

    while read -r number; do
        echo "Kontrollin numbrit $number..."

        if grep -qx "$number" "$lottery_file"; then
            echo "TABAMUS!"
            MATCHES=$((MATCHES + 1))
        else
            echo "Ei tabanud."
        fi

        echo
    done < "$player_file"
}

set_result() {
    local matches="$1"

    case "$matches" in
        5)
            RESULT="JACKPOT!"
            ;;
        4)
            RESULT="Väga hea tulemus!"
            ;;
        3)
            RESULT="Hea tulemus."
            ;;
        2)
            RESULT="Kaks tabamust."
            ;;
        1)
            RESULT="Üks tabamus."
            ;;
        0)
            RESULT="Seekord tabamusi ei olnud."
            ;;
    esac
}

show_result() {
    local player="$1"
    local matches="$2"
    local result="$3"

    echo "Mängija: $player"
    echo "Tabamusi: $matches / 5"
    echo "$result"
}
