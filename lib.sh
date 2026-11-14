log_info() {
    echo "[INFO] $*"
}


log_error() {
    echo "[ERROR] $*" >&2
}


log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> auditor.log
}

require_dir() {
    if [ -d "$1" ]
    then
        return 0
    else
        log_error "Directory does not exist: $1"
        return 1
    fi
}

