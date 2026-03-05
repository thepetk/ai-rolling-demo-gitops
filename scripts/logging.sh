#!/bin/bash

# Color codes for logging
BLUE='\033[34m'
LIGHT_BLUE='\033[94m'
RED='\033[31m'
RESET='\033[0m'

# log: prints an informational message with a timestamp
log() {
  echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${RESET} ${LIGHT_BLUE}INFO${RESET} $*"
}

# log_fail: prints an error message with a timestamp
log_fail() {
  echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${RESET} ${RED}FAIL${RESET} $*"
}
