#!/usr/bin/env bash
# Print basic hardware summary (CPU, RAM, disk, NVIDIA GPUs).
#
#   ./machine-info.sh
#   curl -fsSL https://raw.githubusercontent.com/immanuel-peter/dotfiles/main/machine-info.sh | bash
set -euo pipefail

OS="$(uname -s)"

case "$OS" in
  Linux)
    cpus="$(nproc)"
    ram="$(free -h | awk '/^Mem:/ {print $2}')"
    disk="$(df -h / | awk 'NR==2 {print $2}')"
    ;;
  Darwin)
    cpus="$(sysctl -n hw.ncpu)"
    ram="$(sysctl -n hw.memsize | awk '{gb=$1/1073741824; if (gb == int(gb)) printf "%dGi\n", gb; else printf "%.1fGi\n", gb}')"
    disk="$(df -h / | awk 'NR==2 {print $2}')"
    ;;
  *)
    cpus="unknown"
    ram="unknown"
    disk="$(df -h / 2>/dev/null | awk 'NR==2 {print $2}')"
    disk="${disk:-unknown}"
    ;;
esac

echo "OS:           ${OS}"
echo "CPUs:         ${cpus}"
echo "Architecture: $(uname -m)"
echo "RAM:          ${ram}"
echo "Disk:         ${disk}"

# NVIDIA GPU (if available)
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
  echo "GPU:          $(nvidia-smi --query-gpu=name --format=csv,noheader | awk 'NR==1')"
  echo "GPU Count:    $(nvidia-smi -L | wc -l | tr -d ' ')"
  echo "VRAM per GPU: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader | awk 'NR==1')"
else
  echo "GPU Count:    0"
fi
