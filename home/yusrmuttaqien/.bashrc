# User aliases (available in non-interactive shell)
alias monitor-off-kde="export WAYLAND_DISPLAY=wayland-0 && kscreen-doctor --dpms off"
alias monitor-on-kde="export WAYLAND_DISPLAY=wayland-0 && kscreen-doctor --dpms on"
alias monitor-off="sudo sh -c 'echo 4 > /sys/class/graphics/fb0/blank'"
alias monitor-on="sudo sh -c 'echo 0 > /sys/class/graphics/fb0/blank'"
alias monitor-HDMI-1="sudo ddcutil setvcp 60 x12"
alias monitor-HDMI-2="sudo ddcutil setvcp 60 x11"
alias monitor-Displayport="sudo ddcutil setvcp 60 x0f"

# If not running interactively, don't resume
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Exports for NVCC
export PATH=/opt/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/opt/cuda/lib64

# User aliases
alias sleep-cancel="pkill sleep"
alias sleep-session="echo \"pkill -15 -f 'sshd-session:' ; sleep 1 ; systemctl suspend\" | sudo at now"
alias sleep-lock-session="lockscreen && sudo systemctl suspend"

alias logout="loginctl kill-user '$USER'"
alias reset-sudo="faillock --reset"
alias reset-samba="sudo systemctl restart smb nmb"

alias gpu-undervolt-higher="sudo nvidia-undervolt-higher.py"
alias gpu-undervolt-lower="sudo nvidia-undervolt-lower.py"
alias gpu-undervolt-lowest="sudo nvidia-undervolt-lowest.py"
alias gpu-undervolt-gaming="sudo nvidia-undervolt-gaming.py"
alias gpu-monitor="sudo -v && (( sleep 3 && sudo sh -c 'echo 4 > /sys/class/graphics/fb0/blank' ) & nvtop)"

alias mode-ssh="echo 'Entering SSH Mode: Stopping desktop and sunshine...' && sudo systemctl stop display-manager.service && pkill -u yusrmuttaqien -f 'plasmashell|kwin_wayland|Xwayland|kded6|ksmserver|kscreenlocker|xdg-desktop-portal-kde' && systemctl --user stop app-dev.lizardbyte.app.Sunshine && echo 'Services stopped. VRAM is free. Run nvidia-smi to check.'"
alias mode-headless="pkill deskflow && mode-ssh && gpu-undervolt-lower && auto-sleep-start && sleep 8 && monitor-off"
alias mode-desktop="echo 'Restoring Desktop Mode...' && auto-sleep-stop && sudo systemctl start display-manager.service && echo 'Desktop and Sunshine services are starting.'"

alias resume-tmux="monitor-off && tmux attach"

alias auto-sleep-start="sudo systemctl start autosleep.service"
alias auto-sleep-monitor="journalctl -u autosleep -f"
alias auto-sleep-stop="sudo systemctl stop autosleep.service"

alias download-fast="aria2c -x 16 -s 16"

alias remove-dotfiles='find . \( -iname "._*" -o -iname ".DS*" -o -iname ".fuse*" \) -exec rm -f {} +'

alias check-space='df -h'

alias current-venv="echo $VIRTUAL_ENV"

alias backup-linux="sudo systemctl start linux-backup.service"
alias backup-local-ai="sudo systemctl start local-ai-backup.service"
alias backup-list="restic -r /mnt/HDD\ 1TB/Backup\ repository snapshots"
alias backup-mount="restic mount ~/mnt/restic-snapshot -r /mnt/HDD\ 1TB/Backup\ repository/"

alias cd-user-script="cd /usr/local/bin"
alias cd-service-etc-script="cd /etc/systemd/system"
alias cd-service-usr-script="cd /usr/lib/systemd"
alias cd-models="cd /mnt/AI/models"

alias cls="clear"
alias ls-detail="ls -l --block-size=MB"

alias openlumara="cd ~/Documents/openlumara && ./run.sh"
alias comfyui-stable-3.12="source ~/Documents/ComfyUI/stable-3.12/stable-3.12/bin/activate && comfy launch -- --listen --lowvram --reserve-vram 2.0 --port 30005 $1"

alias reboot-windows="sudo systemctl reboot --boot-loader-entry=auto-windows"
alias reboot-bios="sudo systemctl reboot --boot-loader-entry=auto-reboot-to-firmware-setup"

alias stream-on='docker start stremio && echo "🚀 Stremio started! Access at port 8080, for server at port 11470"'
alias stream-off='docker stop stremio && echo "💤 Stremio stopped."'
alias stream-reboot='docker restart stremio && echo "Rebooting Stremio..."'

alias portainer-on='docker start portainer && echo "🚀 Portainer started! Access at HTTPS protocol at port 9443"'
alias portainer-off='docker stop portainer && echo "💤 Portainer stopped."'

alias searxng-on='docker start searxng redis caddy && echo "🚀 SearXNG started! Access at HTTP protocol at port 30003"'
alias searxng-off='docker stop searxng redis caddy && echo "💤 SearXNG stopped."'

# Appliying environment
source '/home/yusrmuttaqien/.bash_completions/comfy.sh'
source /usr/share/nvm/init-nvm.sh

# Other
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"

# Added by Hugging Face CLI installer
export PATH="/home/yusrmuttaqien/.local/bin:$PATH"

# Add bun globally installed modules access
export PATH="/home/yusrmuttaqien/.bun/bin:$PATH"

# User functions
function brightness-set() {
  echo "Setting brightness to: $1"

  sudo ddcutil setvcp 10 "$1"
}
function cpu-monitor {
    sudo nice -n 19 bash -c '
    MAX=$(cat /sys/class/powercap/intel-rapl:0/max_energy_range_uj)
    old=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
    while true; do
        sleep 1
        new=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

        # Fix: handle RAPL counter overflow
        if [ "$new" -lt "$old" ]; then
            diff=$(( MAX - old + new ))
        else
            diff=$(( new - old ))
        fi

        # Single awk pass for everything (replaces bc + awk + awk + cut)
        awk -v diff="$diff" "
            /cpu MHz/ {
                sum += \$4; count++
                if (\$4 > max) max = \$4
                if (count <= 6) cores = cores sprintf(\"%.0f \", \$4)
            }
            END {
                pwr  = diff / 1000000
                avg  = sum / count
                printf \"\rPwr: %.2fW | Avg: %.0fMHz | Max: %.0fMHz | Cores: [ %s]    \",
                       pwr, avg, max, cores
            }
        " /proc/cpuinfo

        old=$new
    done
    '
}
function llama-unload() {
  curl -X POST http://localhost:30001/models/unload \
    -H "Content-Type: application/json" \
    -d "{\"model\": \"$1\"}"
  echo ""
}
