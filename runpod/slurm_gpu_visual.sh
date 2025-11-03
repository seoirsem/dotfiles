#!/bin/bash
# Minimal GPU status monitor for Slurm

# ANSI codes
GREEN='\033[92m'
BLUE='\033[94m'
GRAY='\033[90m'
BOLD='\033[1m'
RESET='\033[0m'
CLEAR_LINE='\033[K'
CURSOR_HOME='\033[H'
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'

# Get current user - use argument if provided, otherwise whoami
CURRENT_USER=${1:-$(whoami)}
# If running as root, try to get the real user from SUDO_USER or terminal owner
if [[ "$CURRENT_USER" == "root" && -n "$SUDO_USER" ]]; then
    CURRENT_USER="$SUDO_USER"
elif [[ "$CURRENT_USER" == "root" ]]; then
    # Try to get terminal owner
    TTY_OWNER=$(stat -c '%U' $(tty) 2>/dev/null)
    [[ -n "$TTY_OWNER" && "$TTY_OWNER" != "root" ]] && CURRENT_USER="$TTY_OWNER"
fi

# Trap Ctrl+C to restore cursor
trap "echo -ne '$SHOW_CURSOR'; exit" INT TERM

# Clear screen once and hide cursor
clear
echo -ne "$HIDE_CURSOR"

while true; do
    # Move cursor to home position
    echo -ne "$CURSOR_HOME"

    # Get job info: node, user, and GPU count per job
    # Store in temp file to avoid subshell issues
    tmpfile=$(mktemp)
    squeue -t RUNNING -o "%N|%u|%b" --noheader | grep -v "^|" | sed 's/gres\/gpu://g' > "$tmpfile"

    # Get GPU info and display
    sinfo -N --Format=NodeList,Gres,GresUsed --noheader | sort -u | while read line; do
        node=$(echo "$line" | awk '{print $1}')
        total=$(echo "$line" | awk '{print $2}' | grep -oP 'gpu:\K\d+')
        used=$(echo "$line" | awk '{print $3}' | grep -oP 'gpu:\K\d+')

        # Default to 0 if empty
        used=${used:-0}

        # Build GPU boxes - track which user owns which GPUs
        boxes=""
        gpu_idx=0

        # Get jobs running on this node
        while IFS='|' read -r job_node user gpus; do
            # Skip if gpus is not a valid number (e.g., "N/A")
            if [[ "$job_node" == "$node" && "$gpus" =~ ^[0-9]+$ ]]; then
                # Assign GPUs to this job
                for ((j=0; j<gpus; j++)); do
                    if [ $gpu_idx -lt $total ]; then
                        if [[ "$user" == "$CURRENT_USER" ]]; then
                            boxes+="${BLUE}[█]${RESET}"
                        else
                            boxes+="${GREEN}[█]${RESET}"
                        fi
                        ((gpu_idx++))
                    fi
                done
            fi
        done < "$tmpfile"

        # Fill remaining with free GPUs
        for ((i=gpu_idx; i<total; i++)); do
            boxes+="${GRAY}[░]${RESET}"
        done

        # Print node line
        echo -e "${BOLD}${node:0:8}${RESET} ${boxes}${CLEAR_LINE}"
    done

    rm -f "$tmpfile"

    # Summary (unique by node name to avoid partition duplicates)
    gpu_data=$(sinfo -N --Format=NodeList,Gres,GresUsed --noheader | awk '{print $1, $2, $3}' | sort -u -k1,1)
    total_gpus=$(echo "$gpu_data" | grep -oP 'gpu:\K\d+' | awk 'NR%2==1 {s+=$1} END {print s}')
    total_used=$(echo "$gpu_data" | grep -oP 'gpu:\K\d+' | awk 'NR%2==0 {s+=$1} END {print s}')
    echo -e "${CLEAR_LINE}"
    echo -e "${total_used:-0}/${total_gpus:-0} GPUs | $(date '+%H:%M:%S')${CLEAR_LINE}"

    sleep 1
done
