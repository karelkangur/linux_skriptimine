#!/bin/bash

# Lihtne lotomäng

# Mängija ja loosinumbrite failid tühjendatakse iga mängu alguses
> player_numbers.txt
> lottery_numbers.txt

# Küsime mängija nime
read -p "Sisesta mängija nimi: " player_name

if [ -z "$player_name" ]; then
    player_name="Unknown"
fi

echo
echo "Sisesta 5 erinevat numbrit vahemikus 1-50."
echo

# -------------------------
# Mängija numbrite sisestamine
# -------------------------

count=0

while [ "$count" -lt 5 ]; do

    read -p "Sisesta number $((count + 1)): " number

    # Kontroll: midagi peab olema sisestatud
    if [ -z "$number" ]; then
        echo "Viga: number jäi sisestamata."
        continue
    fi

    # Kontroll: peab olema täisarv
    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
        echo "Viga: sisesta täisarv."
        continue
    fi

    # Kontroll: peab olema vahemikus 1-50
    if [ "$number" -lt 1 ] || [ "$number" -gt 50 ]; then
        echo "Viga: number peab olema vahemikus 1-50."
        continue
    fi

    # Kontroll: sama numbrit ei tohi kaks korda sisestada
    if grep -qx "$number" player_numbers.txt; then
        echo "Viga: number $number on juba valitud."
        continue
    fi

    # Salvestame korrektse numbri
    echo "$number" >> player_numbers.txt
    count=$((count + 1))

done

echo
echo "Mängija valitud numbrid:"
cat player_numbers.txt

# -------------------------
# Lotonumbrite loosimine
# -------------------------

count=0

while [ "$count" -lt 5 ]; do

    lottery_number=$((RANDOM % 50 + 1))

    # Kui number on juba loositud, proovime uuesti
    if grep -qx "$lottery_number" lottery_numbers.txt; then
        continue
    fi

    echo "$lottery_number" >> lottery_numbers.txt
    count=$((count + 1))

done

echo
echo "Võidunumbrid:"
cat lottery_numbers.txt

# -------------------------
# Tulemuste kontrollimine
# -------------------------

echo
echo "Tulemuste kontroll:"
echo

matches=0

while read -r number; do

    echo "Kontrollin numbrit $number..."

    if grep -qx "$number" lottery_numbers.txt; then
        echo "TABAMUS!"
        matches=$((matches + 1))
    else
        echo "Ei tabanud."
    fi

    echo

done < player_numbers.txt

echo "Mängija: $player_name"
echo "Tabamusi: $matches / 5"

# -------------------------
# Hinnang tulemusele
# -------------------------

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

echo "$result"

# -------------------------
# Tulemuse salvestamine
# -------------------------

{
    echo "========================================"
    echo "Date: $(date)"
    echo "Player: $player_name"
    echo "Player numbers:"
    cat player_numbers.txt
    echo "Lottery numbers:"
    cat lottery_numbers.txt
    echo "Matches: $matches"
    echo "Result: $result"
} >> results.txt

echo
echo "Tulemus salvestati faili results.txt."
