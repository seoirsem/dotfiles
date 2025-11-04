#!/bin/bash
# Enhanced queue display that shows GPU counts for all jobs

echo "=== GPU Resources by Node ==="
sinfo -N --Format=NodeList,Gres,GresUsed | head -10

echo
echo "=== Running Jobs with GPU Usage ==="

# Header
printf "%-10s %-9s %-20s %-10s %-2s %-10s %-6s %-10s\n" \
  "JOBID" "PARTITION" "NAME" "USER" "ST" "TIME" "NODES" "GPUS"

# Get job data
squeue -t RUNNING -o "%i|%P|%.20j|%u|%t|%M|%D|%b" --noheader | while IFS='|' read -r jobid partition name user state time nodes tres; do
    # Extract GPU count from TRES_PER_NODE
    if [[ "$tres" == "N/A" || "$tres" == "" ]]; then
        # Fallback to scontrol for dev jobs or jobs without TRES_PER_NODE
        gpus=$(scontrol show job "$jobid" 2>/dev/null | grep -oP 'AllocTRES=.*?gres/gpu=\K\d+' || echo "0")
    else
        # Extract GPU count from gres/gpu:N format
        gpus=$(echo "$tres" | grep -oP 'gres/gpu:\K\d+' || echo "0")
    fi

    # Default to 0 if empty
    gpus=${gpus:-0}

    # Print formatted output
    printf "%-10s %-9s %-20s %-10s %-2s %-10s %-6s %-10s\n" \
      "$jobid" "$partition" "$name" "$user" "$state" "$time" "$nodes" "$gpus"
done
