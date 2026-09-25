MY_CONFIG_PATH="$(command cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# assert MY_CONFIG_PATH is valid
if [[ ! -d "$MY_CONFIG_PATH" ]]; then
    echo "Error: [MY_CONFIG_PATH : $MY_CONFIG_PATH] is invalid" >&2
    return 1
fi

# command aliases
alias bat='batcat --paging=never --color=always --style=numbers --line-range=:500'
alias fzf='fzf --preview ""'
alias cls='clear && ls;'
alias clcd='clear && cd'
alias dir='dir --color=always'

# script aliases
alias merge_videos='$MY_CONFIG_PATH/scripts/merge_videos/merge_videos.sh'
alias mdtopdf='$MY_CONFIG_PATH/scripts/mdtopdf'
alias repo='$MY_CONFIG_PATH/scripts/repo'
alias ignore='$MY_CONFIG_PATH/scripts/ignore'

##########################################
######### Aliases for wsl only ###########
if [ -n "$WSL_DISTRO_NAME" ]; then
    alias getclipboard='powershell.exe Get-Clipboard'
fi

source "$MY_CONFIG_PATH/func.sh"
source "$MY_CONFIG_PATH/keybind.sh"
source "$MY_CONFIG_PATH/env.sh"
source "$MY_CONFIG_PATH/scripts/set_shell_prompt"
source "$MY_CONFIG_PATH/scripts/cddr"

export MY_CONFIG_PATH
export EDITOR=nvim
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#eb7b00,fg+:#000000,spinner:#f5e0dc,hl:#eb7b00 \
  --color=fg:#cdd6f4,header:#a6c6ff,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,prompt:#cba6f7,hl+:#ffffff \
  --color=selected-bg:#365e2d \
  --border=rounded \
  --border-label-pos=2 \
  --margin=1 \
  --padding=1 \
  --layout=reverse \
  --height=80% \
  --prompt='  ' \
  --pointer=' ' \
  --marker=' ' \
  --separator='─' \
  --scrollbar='│' \
  --info=inline-right"
