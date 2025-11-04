# -------------------------------------------------------------------
# General and Navigation
# -------------------------------------------------------------------

HOST_IP_ADDR=$(ip route get 1 2>/dev/null | awk '{print $7}' || python3 -c "import socket; print(socket.gethostbyname(socket.gethostname()))" 2>/dev/null || echo "127.0.0.1") # Cross-platform IP address detection

# Quick navigation add more here
alias a="cd ~/git/aladdin"
alias a2="cd ~/git/aladdin2"
alias cde="cd /exp/$(whoami)"
alias cdt="cd ~/tb"
alias cdn="cd ~/notebooks"
alias b="cd ~/git/bladdin"
alias c="cd ~/git/chunky-post-training"
alias w="cd /workspace"
alias cs="cd /workspace-vast/seoirsem/git/chunky-post-training"
alias ws="cd /workspace-vast/seoirsem"
# Perish machines
alias p1="cd /perish_aml01"
alias p2="cd /perish_aml02"
alias p3="cd /perish_aml03"
alias p4="cd /perish_aml04"
alias p5="cd /perish_aml05"
alias g1="cd /perish_g01"
alias g2="cd /perish_g02"
alias g3="cd /perish_g03"

alias b1="ssh b1"
alias b2="ssh b2"
alias b3="ssh b3"
alias b4="ssh b4"
alias b5="ssh b5"
alias b6="ssh b6"
alias b7="ssh b7"

# Change to aladdin directory and activate SIF
alias msa="make -C /home/$(whoami)/git/aladdin/ shell"
alias msa2="make -C /home/$(whoami)/git/aladdin2/ shell"
# Activate aladdin SIF in current directory
alias msad="/home/$(whoami)/git/aladdin/env/singularity.sh -c "$SHELL""
alias msad2="/home/$(whoami)/git/aladdin2/env/singularity.sh -c "$SHELL""

# Parquet printing utilities
PARQUET_ENV_ERROR_MESSAGE="ERROR: Open a singularity environment before using pcat, pless, phead or ptail"
alias pcat="[ -z '$SINGULARITY_CONTAINER' ] && echo $PARQUET_ENV_ERROR_MESSAGE || python $CODE_DIR/aladdin/utils/parquet_text_printer.py"
alias phead="[ -z '$SINGULARITY_CONTAINER' ] && echo $PARQUET_ENV_ERROR_MESSAGE || python $CODE_DIR/aladdin/utils/parquet_text_printer.py --mode head"
alias ptail="[ -z '$SINGULARITY_CONTAINER' ] && echo $PARQUET_ENV_ERROR_MESSAGE || python $CODE_DIR/aladdin/utils/parquet_text_printer.py --mode tail"
function pless () { pcat $@ | less; }

# Misc
alias jp="jupyter lab --no-browser --ip 0.0.0.0"
alias tb="tensorboard --reload_multifile true --bind_all  --logdir=$PWD --reload_interval 3 --extra_data_server_flags=--no-checksum --max_reload_threads 4 --window_title $PWD"
alias ls='ls -hF --color' # add colors for filetype recognition
alias nv='nvidia-smi'

# make file
alias m='make'
alias mc="make check"
alias ms='make shell'
alias mf="make format"
alias mtest="make test"
alias mft="make functest"
alias mut="make unittest"

# -------------------------------------------------------------------
# Tensorboard
# -------------------------------------------------------------------

tblink () {
    [ -z $SINGULARITY_CONTAINER ] && echo "must be run inside SIF" && return
    # Creates simlinks from specified folders to ~/tb/x where x is an incrmenting number
    # and luanches tensorboard
    # example: `tblink ./lm/20210824 ./lm/20210824_ablation ./lm/20210825_updated_data`
    if [ "$#" -eq 0 ]; then
        logdir=$(pwd)
    else
        # setup tensorboard directory
        tbdir="$HOME/tb"
        if [ -d "$tbdir" ]; then
            last="$(printf '%s\n' $tbdir/* | sed 's/.*\///' | sort -g -r | head -n 1)"
            new=$((last+1))
            echo "last folder $last, new folder $new"
            logdir="$tbdir/$new"
        else
            logdir="$tbdir/0"
        fi
        # softlink into tensorboard directory
        _linkdirs "$logdir" "$@"
    fi
    tensorboard \
      --reload_multifile true \
      --logdir="$logdir" \
      --bind_all \
      --reload_interval 8 \
      --max_reload_threads 4 \
      --window_title $PWD 
}
_linkdirs() {
    logdir="$1"
    mkdir -p $logdir
    for linkdir in "${@:2}"; do
        linkdir=$(readlink -f $linkdir)
        if [ ! -d $linkdir ]; then
            echo "linkdir $linkdir does not exist"
            return
        fi
        echo "symlinked $linkdir into $logdir"
        ln -s $linkdir $logdir
    done
}
tbadd() {
    # Add experiment folder to existing tensorboard directory (see tblink)
    # example: `tbadd 25 ./lm/20210825` will symlink ./lm/20210824 to ~/tb/25
    if [ "$#" -gt 1 ]; then
        tbdir="$HOME/tb"
        logdir=$tbdir/$1
        _linkdirs $logdir "${@:2}"
    else
        echo "tbadd <tb number> <exp dirs>"
    fi
}

# -------------------------------------------------------------------
# Queue management
# -------------------------------------------------------------------

# Short aliases
full_queue='qstat -q "aml*.q@*" -f -u \*'
alias q='/home/seoirsem/git/dotfiles/runpod/slurm_queue_display.sh'
alias qtop='qalter -p 1024'
alias qq=$full_queue # Display full queue
alias gq='qstat -q aml-gpu.q -f -u \*' # Display just the gpu queues
alias gqf='qstat -q aml-gpu.q -u \* -r -F gpu | egrep -v "jobname|Master|Binding|Hard|Soft|Requested|Granted"' # Display the gpu queues, including showing the preemption state of each job
alias cq='qstat -q "aml-cpu.q@gpu*" -f -u \*' # Display just the cpu queues
alias wq="watch qstat"
alias wqq="watch $full_queue"
alias wg="/home/seoirsem/git/dotfiles/runpod/slurm_gpu_visual.sh \$(whoami)"  # Visual GPU status monitor for Slurm

# Queue functions
qlogin () {
  # Function to request GPU access via Slurm
  # example:
  #    qlogin 2    request 2 gpus
  #    qlogin 1    request 1 gpu
  if [ "$#" -eq 1 ]; then
    srun --job-name=D_$(whoami) --partition=dev,overflow --qos=dev --gres=gpu:$1 --pty zsh -c "source /workspace-vast/seoirsem/git/dotfiles/config/zshrc.sh; source /workspace-vast/seoirsem/git/dotfiles/config/aliases_speechmatics.sh; exec zsh"
  else
    echo "Usage: qlogin <num_gpus>" >&2
  fi
}

qsub() {
  # Generic Slurm job submission wrapper
  # Usage: qsub <num_gpus> [options] -- <command>

  if [ "$#" -lt 3 ]; then
    echo "Usage: qsub <num_gpus> [options] -- <command>" >&2
    echo "Options:" >&2
    echo "  --work-dir DIR      Job script location (default: auto-generated)" >&2
    echo "  --run-dir DIR       Directory to run command in (default: \$PWD)" >&2
    echo "  --env-file FILE     Source env file before running" >&2
    echo "  --preserve-env      Export all current env vars" >&2
    echo "  Any other sbatch flags (--mem, --partition, etc.)" >&2
    echo "" >&2
    echo "Default resources:" >&2
    echo "  --mem: (num_gpus * 80)G  # Override with --mem flag if needed" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  qsub 4 -- uv run python train.py" >&2
    echo "  qsub 2 -- 'echo hello >> file.txt'  # Quote shell operators" >&2
    echo "  qsub 8 --mem 1600G -- 'python train.py && echo done'  # Override memory" >&2
    return 1
  fi

  local num_gpus=$1
  shift

  # Parse options
  local sbatch_opts=""
  local work_dir=""
  local run_dir="$PWD"  # Default to current directory
  local env_file=""
  local preserve_env=false

  while [[ "$1" != "--" && "$#" -gt 0 ]]; do
    case "$1" in
      --work-dir)
        work_dir="$2"
        shift 2
        ;;
      --run-dir)
        run_dir="$2"
        shift 2
        ;;
      --env-file)
        env_file="$2"
        shift 2
        ;;
      --preserve-env)
        preserve_env=true
        shift
        ;;
      *)
        sbatch_opts="$sbatch_opts $1"
        shift
        ;;
    esac
  done

  if [[ "$1" != "--" ]]; then
    echo "Error: Missing '--' separator before command" >&2
    return 1
  fi
  shift

  # Store remaining args for the command
  local command_args=("$@")

  # Check if we need shell interpretation (contains redirects, pipes, etc.)
  local needs_shell=false
  local full_cmd="$*"
  if [[ "$full_cmd" =~ [\>\<\|] || "$full_cmd" =~ "&&" || "$full_cmd" =~ "||" ]]; then
    needs_shell=true
  fi

  # Default work directory for job script
  if [[ -z "$work_dir" ]]; then
    local timestamp=$(date +%Y%m%d_%H%M%S)
    work_dir="/workspace-vast/$(whoami)/exp/${timestamp}_qsub"
  fi

  mkdir -p "$work_dir/logs"

  # Create sbatch script
  local script_file="$work_dir/job.sh"
  cat > "$script_file" <<EOF
#!/bin/bash
#SBATCH --job-name=qsub_$(whoami)
#SBATCH --output=$work_dir/logs/job.out
#SBATCH --error=$work_dir/logs/job.out
#SBATCH --gres=gpu:${num_gpus}
#SBATCH --partition=high
#SBATCH --qos=high
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=$((num_gpus * 80))G
EOF

  # Add additional sbatch options with proper #SBATCH prefix
  if [[ -n "$sbatch_opts" ]]; then
    for opt in $sbatch_opts; do
      echo "#SBATCH $opt" >> "$script_file"
    done
  fi

  cat >> "$script_file" <<EOF

# Change to run directory
cd $run_dir

EOF

  # Add environment setup if requested
  if [[ "$preserve_env" == true ]]; then
    echo "# Preserve current environment" >> "$script_file"
    env | grep -v '^_' | while IFS='=' read -r key value; do
      # Skip some variables that shouldn't be preserved
      if [[ ! "$key" =~ ^(SHLVL|PWD|OLDPWD|PS1|PROMPT)$ ]]; then
        printf 'export %s=%q\n' "$key" "$value" >> "$script_file"
      fi
    done
    echo "" >> "$script_file"
  fi

  # Auto-load .env from run directory if it exists (unless --env-file was specified)
  if [[ -z "$env_file" && -f "$run_dir/.env" ]]; then
    env_file="$run_dir/.env"
  fi

  if [[ -n "$env_file" ]]; then
    echo "# Load environment file" >> "$script_file"
    echo "export \$(grep -v '^#' $env_file | xargs)" >> "$script_file"
    echo "" >> "$script_file"
  fi

  # Add the command
  if [[ "$needs_shell" == true ]]; then
    # Auto-wrap in bash -c for shell operators
    printf 'bash -c %q' "$full_cmd" >> "$script_file"
    echo "" >> "$script_file"
  else
    # No shell operators, write args normally
    for arg in "${command_args[@]}"; do
      # If arg contains spaces, quotes, or special chars, quote it
      if [[ "$arg" =~ [[:space:]\'\"\$] ]]; then
        printf '%q ' "$arg" >> "$script_file"
      else
        printf '%s ' "$arg" >> "$script_file"
      fi
    done
    echo "" >> "$script_file"
  fi

  # Submit
  local job_id=$(sbatch --parsable "$script_file")
  echo "Submitted job $job_id"
  echo "Run dir: $run_dir"
  echo "Work dir: $work_dir"
  echo "Logs: tail -f $work_dir/logs/job.out"
  echo "Cancel: scancel $job_id"
}
qtail () {
  if [ "$#" -gt 0 ]; then
    l=$(qlog $@) && tail -f $l
  else
    echo "Usage: qtail <jobid>" >&2
    echo "Usage: qtail <array_jobid> <sub_jobid>" >&2
  fi
}
qlast () {
  # Get job_id of last running job
  job_id=$(qstat | awk '$5=="r" {print $1}' | grep -E '[0-9]' | sort -r | head -n 1)
  if [ ! -z $job_id ]; then
    echo $job_id
  else
    echo "no jobs found" >&2
  fi
}
qless () {
  less $(qlog $@)
}
qcat () {
  l=$(qlog $@) && cat $l
}
echo_if_exist() {
  [ -f $1 ] && echo $1
}
qlog () {
  # Get log path of job
  if [ "$1" = "-l" ]; then
    job_id=$(qlast)
  else
    job_id=$1
  fi
  if [ "$#" -eq 1 ]; then
    echo $(qstat -j $job_id | grep stdout_path_list | cut -d ":" -f4)
  elif [ "$#" -eq 2 ]; then
    # Array jobs are a little tricky
    log_path=$(qlog $job_id)
    base_dir=$(echo $log_path | rev | cut -d "/" -f3- | rev)
    filename=$(basename $log_path)
    # Could be a number of schemes so just try them all
    echo_if_exist ${base_dir}/log/${filename} && return 0
    echo_if_exist ${base_dir}/log/${filename%.log}${2}.log && return 0
    echo_if_exist ${base_dir}/log/${filename%.log}.${2}.log && return 0
    echo_if_exist ${base_dir}/${filename%.log}.${2}.log  && return 0
    echo_if_exist ${base_dir}/${filename%.log}${2}.log && return 0
    echo "log file for job $job_id not found" >&2 && return 1
  else
    echo "Usage: qlog <jobid>" >&2
    echo "Usage: qlog <array_jobid> <sub_jobid>" >&2
  fi
}
qdesc () {
  qstat | tail -n +3 | while read line; do
  job=$(echo $line | awk '{print $1}')
  if [[ ! $(qstat -j $job | grep "job-array tasks") ]]; then
    echo $job $(qlog $job)
  else
    qq_dir=$(qlog $job)
    job_status=$(echo $line | awk '{print $5}')
    if [ $job_status = 'r' ]; then
      sub_job=$(echo $line | awk '{print $10}')
      echo $job $sub_job $(qlog $job $sub_job)
    else
      echo $job $qq_dir $job_status
    fi
  fi
done
}

qrecycle () {
  [ ! -z $SINGULARITY_CONTAINER ] && ssh localhost "qrecycle $@" || command qrecycle "$@";
}

qupdate () {
  [ ! -z $SINGULARITY_CONTAINER ] && ssh localhost "qupdate"|| command qupdate ;
}

# Only way to get a gpu is via queue
# Commented out - this was hiding GPUs on RunPod
# if [ -z $CUDA_VISIBLE_DEVICES ]; then
#   export CUDA_VISIBLE_DEVICES=
# fi

# -------------------------------------------------------------------
# Cleaning processes
# -------------------------------------------------------------------

clean_vm () {
  ps -ef | grep zsh | awk '{print $2}' | xargs sudo kill
  ps -ef | grep vscode | awk '{print $2}' | xargs sudo kill
}

