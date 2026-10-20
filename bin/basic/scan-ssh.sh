#!/usr/bin/env bash

# 1. You can still hardcode the specific SSH public key string here if you prefer
# Example: SEARCH_KEY="ssh-ed25519 AAAAC3NzaC1... user@local"
SEARCH_KEY=""

# 2. Set the default maximum number of parallel connections
MAX_CONCURRENT=5

# Function to display help menu
show_help() {
    echo "Usage: ./scan-ssh.sh [OPTIONS]"
    echo ""
    echo "This script connects to all hosts in your ~/.ssh/config and scans for a specific SSH public key in ~/.ssh/authorized_keys."
    echo ""
    echo "Options:"
    echo "  -k, --key <string>    The exact SSH public key string to search for."
    echo "  -d, --delete          Delete the key from authorized_keys on the remote host if found."
    echo "  -c, --concurrent <N>  Set the maximum number of parallel connections (default: 5)."
    echo "  -v, --verbose         Enable debug mode. Saves verbose SSH output to a timestamped log file."
    echo "  -h, --help            Display this help message and exit."
    echo ""
    echo "Example:"
    echo "  ./scan-ssh.sh -k 'ssh-ed25519 AAAAC3NzaC1...' -c 10 -v"
    exit 0
}

# 3. Parse command-line arguments
DELETE_MODE=0
DEBUG_MODE=0
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--delete) DELETE_MODE=1; shift ;;
        -v|--verbose) DEBUG_MODE=1; shift ;;
        -k|--key) SEARCH_KEY="$2"; shift 2 ;;
        -c|--concurrent) MAX_CONCURRENT="$2"; shift 2 ;;
        -h|--help) show_help ;;
        *) echo "Unknown parameter passed: $1"; echo "Run ./scan-ssh.sh --help for usage."; exit 1 ;;
    esac
done

# Split into if/elif to avoid the formatting engine hijacking the OR operator
if [ -z "$SEARCH_KEY" ]; then
    echo "Error: Please provide your public key via the -k parameter (e.g., -k 'ssh-ed25519...') or set it inside the script."
    exit 1
elif [ "$SEARCH_KEY" == "YOUR_SSH_PUBLIC_KEY_HERE" ]; then
    echo "Error: Please provide your public key via the -k parameter (e.g., -k 'ssh-ed25519...') or set it inside the script."
    exit 1
fi

# SSH Pilot manages connections in your standard SSH config
SSH_CONFIG="$HOME/.ssh/config"

if [ ! -f "$SSH_CONFIG" ]; then
    echo "No SSH config file found at $SSH_CONFIG."
    exit 1
fi

# Extract all 'Host' entries from the config (ignoring wildcards like '*')
HOSTS=$(awk '/^Host / {
    for (i=2; i<=NF; i++) {
        if ($i !~ /\*/) print$i
    }
}' "$SSH_CONFIG")

# Set up logging ONLY if DEBUG_MODE is active
LOG_FILE="/dev/null"
if [ "$DEBUG_MODE" -eq 1 ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    # Using $PWD explicitly refers to the current working directory from where the command was executed
    LOG_FILE="$PWD/ssh_scan_${TIMESTAMP}.log"
    
    # Check if we have permission to create/write the log file BEFORE starting the script
    if ! touch "$LOG_FILE" 2>/dev/null; then
        echo "Error: Cannot write to execution directory ($PWD). Please check your permissions."
        exit 1
    fi
    
    # Ensure it is empty if it somehow already existed
    echo "" > "$LOG_FILE"
    echo "📄 Detailed debug log will be saved to: $LOG_FILE"
    
    # Catch interruptions (Ctrl+C) and standard exits to clean up leftover local tmp files
    trap 'rm -f "${LOG_FILE}".*.tmp 2>/dev/null' EXIT INT TERM
fi

if [ "$DELETE_MODE" -eq 1 ]; then
    echo "⚠  DELETE MODE ENABLED. Keys will be removed if found."
fi
echo "Checking hosts for the specified key using $MAX_CONCURRENT parallel connections..."
echo "------------------------------------------------"

# Pipe the hosts into xargs for parallel execution
echo "$HOSTS" | tr ' ' '\n' | xargs -r -n 1 -P "$MAX_CONCURRENT" bash -c '
    SEARCH_KEY=$1
    DELETE_MODE=$2
    DEBUG_MODE=$3
    LOG_FILE=$4
    HOST=$5
    
    # Common SSH options - Added KbdInteractiveAuthentication=no and NumberOfPasswordPrompts=0
    SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o NumberOfPasswordPrompts=0 -o ConnectTimeout=5"
    
    # If debug mode is active, add the -v flag and prepare the temporary log file
    if [ "$DEBUG_MODE" -eq 1 ]; then
        SSH_OPTS="-v $SSH_OPTS"
        TMP_LOG="${LOG_FILE}.${HOST}.tmp"
        echo -e "\n========================================================" > "$TMP_LOG"
        echo " HOST: $HOST | TIME: $(date)" >> "$TMP_LOG"
        echo "========================================================" >> "$TMP_LOG"
    else
        # If no debug mode, send errors silently to /dev/null
        TMP_LOG="/dev/null"
    fi
    
    # First, check if the key exists.
    if echo "$SEARCH_KEY" | ssh $SSH_OPTS "$HOST" "grep -F -q -f - ~/.ssh/authorized_keys" 2>> "$TMP_LOG"; then
        
        if [ "$DELETE_MODE" -eq 1 ]; then
            # Delete mode
            if echo "$SEARCH_KEY" | ssh $SSH_OPTS "$HOST" "grep -v -F -f - ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp && cat ~/.ssh/authorized_keys.tmp > ~/.ssh/authorized_keys && rm ~/.ssh/authorized_keys.tmp" 2>> "$TMP_LOG"; then
                echo "🗑  [DELETED] The key was removed from: $HOST"
            else
                echo "❌ [ERROR] Found the key but failed to delete on: $HOST"
            fi
        else
            echo "✅ [FOUND] The key is authorized on: $HOST"
        fi
        
    else
        echo "➖ [MISS] Key not found, host unreachable, or no access to the server: $HOST"
    fi
    
    # If debugging, append this host s temporary log to the main log file and clean up
    if [ "$DEBUG_MODE" -eq 1 ]; then
        cat "$TMP_LOG" >> "$LOG_FILE" 2>/dev/null
        rm -f "$TMP_LOG" 2>/dev/null
    fi
' _ "$SEARCH_KEY" "$DELETE_MODE" "$DEBUG_MODE" "$LOG_FILE"

echo "------------------------------------------------"
if [ "$DEBUG_MODE" -eq 1 ]; then
    echo "Scan complete. Review the debug log at: $LOG_FILE"
else
    echo "Scan complete."
fi