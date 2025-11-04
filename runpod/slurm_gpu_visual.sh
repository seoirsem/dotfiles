#!/bin/bash
# Minimal GPU status monitor for Slurm

# ANSI codes
GREEN='\033[92m'
BLUE='\033[94m'
YELLOW='\033[93m'
RED='\033[91m'
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
    # Build entire output in a buffer first
    output=""

    # Get job info: node, user, partition, QoS, and GPU count per job
    # Store in temp file to avoid subshell issues
    tmpfile=$(mktemp)
    squeue -t RUNNING -o "%i|%N|%u|%P|%q|%b" --noheader | grep -v "^|" | sed 's/gres\/gpu://g' > "$tmpfile"

    # Get GPU info and build node array
    node_lines=()
    unset seen_nodes
    declare -A seen_nodes
    while read line; do
        node=$(echo "$line" | awk '{print $1}')

        # Skip if we've already processed this node
        [[ -n "${seen_nodes[$node]}" ]] && continue
        seen_nodes[$node]=1

        total=$(echo "$line" | awk '{print $2}' | grep -oP 'gpu:\K\d+')
        used=$(echo "$line" | awk '{print $3}' | grep -oP 'gpu:\K\d+')

        # Default to 0 if empty
        used=${used:-0}

        # Shorten node name: node-123 -> 123
        display_node="${node#node-}"

        # Build GPU boxes - track which user owns which GPUs
        boxes=""
        gpu_idx=0

        # Get jobs running on this node
        while IFS='|' read -r jobid job_node user partition qos gpus; do
            if [[ "$job_node" == "$node" ]]; then
                # If gpus is N/A, query scontrol for actual GPU allocation
                if [[ "$gpus" == "N/A" ]]; then
                    gpus=$(scontrol show job "$jobid" 2>/dev/null | grep -oP 'AllocTRES=.*?gres/gpu=\K\d+' || echo "0")
                fi

                # Skip if gpus is still not a valid number
                if [[ "$gpus" =~ ^[0-9]+$ ]]; then
                    # Assign GPUs to this job
                    for ((j=0; j<gpus; j++)); do
                        if [ $gpu_idx -lt $total ]; then
                            # Color logic: red/yellow for dev partition OR overflow with dev qos
                            # blue/green for other jobs
                            is_interactive=false
                            if [[ "$partition" == "dev" ]] || [[ "$partition" == "overflow" && "$qos" == "dev" ]]; then
                                is_interactive=true
                            fi

                            if [[ "$is_interactive" == true && "$user" == "$CURRENT_USER" ]]; then
                                boxes+="${RED}█${RESET}"
                            elif [[ "$is_interactive" == true ]]; then
                                boxes+="${YELLOW}█${RESET}"
                            elif [[ "$user" == "$CURRENT_USER" ]]; then
                                boxes+="${BLUE}█${RESET}"
                            else
                                boxes+="${GREEN}█${RESET}"
                            fi
                            ((gpu_idx++))
                        fi
                    done
                fi
            fi
        done < "$tmpfile"

        # Fill remaining with free GPUs
        for ((i=gpu_idx; i<total; i++)); do
            boxes+="${GRAY}░${RESET}"
        done

        # Store node line for later display
        node_lines+=("${BOLD}${display_node}${RESET} ${boxes}")
    done < <(sinfo -N --Format=NodeList,Gres,GresUsed --noheader | sort)

    # Get terminal width
    term_width=$(tput cols)

    # Calculate approximate width per node (display_node + space + 8 GPUs + margin)
    # Assuming max 8 GPUs per node and node name ~3 chars
    node_width=15
    nodes_per_row=$((term_width / node_width))
    [[ $nodes_per_row -lt 1 ]] && nodes_per_row=1

    # Build grid output
    col=0
    for node_line in "${node_lines[@]}"; do
        output+="${node_line}"
        ((col++))
        if [[ $col -ge $nodes_per_row ]]; then
            output+="${CLEAR_LINE}\n"
            col=0
        else
            output+="  "  # spacing between columns
        fi
    done
    [[ $col -gt 0 ]] && output+="${CLEAR_LINE}\n"

    rm -f "$tmpfile"

    # Summary (unique by node name to avoid partition duplicates)
    gpu_data=$(sinfo -N --Format=NodeList,Gres,GresUsed --noheader | awk '{print $1, $2, $3}' | sort -u -k1,1)
    total_gpus=$(echo "$gpu_data" | grep -oP 'gpu:\K\d+' | awk 'NR%2==1 {s+=$1} END {print s}')
    total_used=$(echo "$gpu_data" | grep -oP 'gpu:\K\d+' | awk 'NR%2==0 {s+=$1} END {print s}')
    output+="${CLEAR_LINE}\n"
    output+="${total_used:-0}/${total_gpus:-0} GPUs | $(date '+%H:%M:%S')${CLEAR_LINE}"

    # Move cursor to home, write all output at once, then clear to end of screen
    tput cup 0 0
    echo -ne "$output"
    tput ed

    sleep 1
done
