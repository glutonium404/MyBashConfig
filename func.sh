##################################################
##########      custom functions    ##############
##################################################

mcd() {
    local dir="$1"

    # check if no argument is given
    if [[ -z "$dir" ]]; then
        echo "Usage: mcd <directory>"
        return 1
    fi

    if mkdir "$dir"; then
        cd "$dir" || return
    fi
}

cd() {
    builtin cd "$@" && ls
}

# Function to get the current Git branch and status. using it to modify the shell prompt
parse_git_branch() {
    # Get the current branch name
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            # Uncommitted changes detected
            printf "\001\e[0m\e[1;91m\002(%s)\001\e[0m\002 " "$branch"
        else
            # Clean working tree
            printf "\001\e[0m\e[1;92m\002(%s)\001\e[0m\002 " "$branch"
        fi
    fi
}

yt() {
    local url="https://www.youtube.com/"

    if [[ "$#" -gt 0 ]]; then
        local args="$*"
        local search_query="${args// /+}" # replace all white space with +
        url="https://www.youtube.com/results?search_query=$search_query"
    fi

    echo "$url"
    xdg-open "$url"
}

cddr() {
    fd -t d -L --hidden \
        --max-depth 20 \
        --base-directory "$HOME" \
        > "$HOME/.local/fzf_cache/dirs.txt"
}

ignore() {
    if [[ -z "$MY_CONFIG_PATH" ]]; then
        echo "ERROR: MY_CONFIG_PATH variable is not defined" >&2
        return 1
    fi

    bash "$MY_CONFIG_PATH/scripts/ignore" "$@"
}

cdd() {
    local open_in_editor=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--open)
                open_in_editor=true
                shift
                ;;
            -*)
                echo "Unknow flag $1"
                return 1
                ;;
        esac
    done

    local dir
    dir=$(fzf --border-label='   Search Directories ' < "$HOME/.local/fzf_cache/dirs.txt")
    local full_dir_path="$HOME/$dir"

    if [[ -d "$full_dir_path" ]]; then
        if $open_in_editor; then
            nvim "$full_dir_path"
        else
            cd "$full_dir_path" || return 1
        fi
    else
        echo "No valid directory selected."
    fi
}

mdpdf() {
    local view=false
    local style=false

    # check if -v or --view flag is passed or -s or --style flag is passed
    while [[ "$1" != "" ]]; do
        case $1 in
            -v | --view )    view=true
                ;;
            -s | --style )   style=true
                ;;
            * )              echo "Usage: mdpdf [-v|--view] [-s|--style]"
                return
        esac
        shift
    done

    local md_files
    md_files=$(fd -e md --maxdepth 1) || return

    if [[ -z "$md_files" ]]; then
        echo "No markdown files found."
        return
    fi

    # check if md_files contain only one file
    local file
    if [[ $(echo "$md_files" | wc -l) -eq 1 ]]; then
        file="$md_files"
    else
        file=$(echo "$md_files" | fzf --prompt="Select a markdown file: ") || return
    fi

    local fileNameWithoutExt="${file%.*}"

    if $style; then
        local css_file
        css_file=$(find . -type f -name "style.css" --maxdepth 1)

        if [[ -z "$css_file" ]]; then
            css_file=$(fd . -e css --maxdepth 1 | fzf --prompt="Select a CSS file: ") || return
        fi

        pandoc --pdf-engine=wkhtmltopdf "$file" -o "${fileNameWithoutExt}.pdf" -c "$css_file"
    else
        pandoc --pdf-engine=wkhtmltopdf "$file" -o "${fileNameWithoutExt}.pdf"
    fi

    if $view; then
        echo "Opening ${fileNameWithoutExt}.pdf..."
        xdg-open "${fileNameWithoutExt}.pdf"
    fi
}

clone() {
    local repo_name
    repo_name="$(gh repo list --json nameWithOwner --jq '.[].nameWithOwner' | fzf)"

    [[ -z "$repo_name" ]] && return
    gh repo clone "$repo_name"
}

repo() {
    local open_current=$1

    if [[ "$open_current" == "-c" || "$open_current" == "--current" ]]; then
        local url
        url=$(git remote get-url origin 2> /dev/null)

        if [[ -z "$url" ]]; then
            echo "Error: no origin found for working dir"
            return 1
        fi

        xdg-open "$url"
    else
        local repo_name
        repo_name="$(gh repo list --json nameWithOwner --jq '.[].nameWithOwner' | fzf)"

        [[ -z "$repo_name" ]] && return
        xdg-open "https://github.com/$repo_name"
    fi
}

run() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
    local save_dir="$cache_dir/my_dir"
    local save_file="$save_dir/my_variables.sh"

    # 1. Load saved state if it exists so -p works in new sessions
    if [[ -f "$save_file" ]]; then
        # shellcheck source=/dev/null
        source "$save_file"
    fi

    case "$1" in
        -p)
            if [[ -z "$PREVIOUSLY_RAN_CPP" ]]; then
                echo "No previous file recorded."
            elif [[ ! -f "$PREVIOUSLY_RAN_CPP" ]]; then
                echo "Previous file no longer exists: $PREVIOUSLY_RAN_CPP"
            else
                g++ "$PREVIOUSLY_RAN_CPP" && ./a.out && rm a.out
            fi
            ;;
        "")
            # 2. Check for fd or fd
            local fd_cmd
            fd_cmd=$(command -v fd || command -v fdfind)

            if [[ -z "$fd_cmd" ]]; then
                echo "Error: fd or fd is not installed."
                return 1
            fi

            local file
            file=$($fd_cmd . -e cpp -e c | fzf)

            if [[ -z "$file" ]]; then
                echo "No file selected."
                return
            fi

            # 3. Setup directory and save absolute path
            mkdir -p "$save_dir"
            local abs_path
            abs_path=$(realpath "$file")

            echo "PREVIOUSLY_RAN_CPP=\"$abs_path\"" > "$save_file"
            # shellcheck source=/dev/null
            source "$save_file"

            g++ "$abs_path" && ./a.out && rm a.out
            ;;
        *)
            echo "Usage: run [-p]"
            return 1
            ;;
    esac
}

bashrc() {
    local file="$HOME/.bashrc"

    case "$1" in
        -v)
            nvim -R "$file"
            ;;
        -o)
            cat "$file"
            ;;
        -e)
            nvim "$file"
            ;;
        "")
            # shellcheck disable=SC1090
            source "$file"
            echo -e "\033[0;32m  .bashrc sourced\033[0m"
            ;;
        *)
            echo "Usage: bashrc [-o | -e]"
            return 1
            ;;
    esac
}

chtsh() {
    curl "cht.sh/$1" | batcat
}

gem() {
    local temp_file
    temp_file=$(mktemp)
    trap 'rm -rf "$temp_file"' EXIT

    gemini_beta "$@" > "$temp_file"
    batcat "$temp_file"
    cat "$temp_file"
}

compress() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "Error: ffmpeg is required to use this command."
        return 1
    fi

    local input_file="$1"

    if [[ ! -f "$input_file" ]]; then
        echo "Error: Given Path $input_file is not a valid file" >&2
        return 1
    fi

    local mime_type
    mime_type="$(file --mime-type -b "$input_file")"

    if [[ "$mime_type" != video/* ]]; then
        echo "Error: File $input_file is not of mime-type video/*" >&2
        return 1
    fi

    local dir filename
    dir="$(dirname "$input_file")"
    filename="$(basename "$input_file")"

    ffmpeg -i "$input_file" -vcodec libx265 -crf 28 "$dir/compressed_$filename"
}

video_length() {
    local vid="$1"

    if [[ ! -f "$vid" ]]; then
        echo "Error: file '$vid' is not a valid file path" >&2
        return 1
    fi

    local mime_type
    mime_type="$(file --mime-type -b "$vid")"
    if [[ "$mime_type" != video/* ]]; then
        echo "Error: file '$vid' is not a valid video file" >&2
        return 1
    fi

    local duration
    duration="$(ffprobe -v error -show_entries format=duration -sexagesimal -of default=noprint_wrappers=1:nokey=1 "$vid")"

    if [[ -z "$duration" ]]; then
        echo "Error: Could not extract duration" >&2
        return 1
    fi

    echo "${duration%.*}"
}
