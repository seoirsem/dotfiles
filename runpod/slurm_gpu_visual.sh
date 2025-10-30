#!/bin/bash
# Minimal GPU status monitor for Slurm

# ANSI codes
GREEN='\033[92m'
GRAY='\033[90m'
BOLD='\033[1m'
RESET='\033[0m'
CLEAR_LINE='\033[K'
CURSOR_HOME='\033[H'
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'

# Trap Ctrl+C to restore cursor
trap "echo -ne '$SHOW_CURSOR'; exit" INT TERM

# Clear screen once and hide cursor
clear
echo -ne "$HIDE_CURSOR"

while true; do
    # Move cursor to home position
    echo -ne "$CURSOR_HOME"

    # Get GPU info
    sinfo -N --Format=NodeList,Gres,GresUsed --noheader | sort -u | while read line; do
        node=$(echo "$line" | awk '{print $1}')
        total=$(echo "$line" | awk '{print $2}' | grep -oP 'gpu:\K\d+')
        used=$(echo "$line" | awk '{print $3}' | grep -oP 'gpu:\K\d+')

        # Default to 0 if empty
        used=${used:-0}

        # Build GPU boxes
        boxes=""
        for ((i=0; i<total; i++)); do
            if [ $i -lt $used ]; then
                boxes+="${GREEN}[█]${RESET}"
            else
                boxes+="${GRAY}[░]${RESET}"
            fi
        done

        # Print node line
        echo -e "${BOLD}${node:0:8}${RESET} ${boxes}${CLEAR_LINE}"
    done

    # Summary (unique by node name to avoid partition duplicates)
    gpu_data=$(sinfo -N --Format=NodeList,Gres,GresUsed --noheader | awk '{print $1, $2, $3}' | sort -u -k1,1)
    total_gpus=$(echo "$gpu_data" | grep -oP 'gpu:\K\d+' | awk 'NR%2==1 {s+=$1} END {print s}')
    total_used=$(echo "$gpu_data" | grep -oP 'gpu:\K\d+' | awk 'NR%2==0 {s+=$1} END {print s}')
    echo -e "${CLEAR_LINE}"
    echo -e "${total_used:-0}/${total_gpus:-0} GPUs | $(date '+%H:%M:%S')${CLEAR_LINE}"

    sleep 2
done
