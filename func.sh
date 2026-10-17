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
        cd "$dir" || return 1
    else
        echo "Error: something went wrong" >&2
    fi
}

cd() {
    builtin cd "$@" && ls
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

run() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
    local save_dir="$cache_dir/my_dir"
    local save_file="$save_dir/my_variables.sh"
    local verbose=false
    local previous=false
    local new=false

    # 1. Load saved state if it exists so -p works in new sessions
    if [[ -f "$save_file" ]]; then
        # shellcheck source=/dev/null
        source "$save_file"
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -p|--previous)
                previous=true
                shift
                ;;
            "")
                new=true
                shift
                ;;
            *)
                echo "Usage: run [-p|--previous] [-v|--verbose]"
                return 1
                ;;
        esac
    done

    if $previous; then
        if [[ -z "$PREVIOUSLY_RAN_CPP" ]]; then
            echo "No previous file recorded."
        elif [[ ! -f "$PREVIOUSLY_RAN_CPP" ]]; then
            echo "Previous file no longer exists: $PREVIOUSLY_RAN_CPP"
        else
            $verbose && echo -e "Running: $PREVIOUSLY_RAN_CPP\n\n"
            g++ "$PREVIOUSLY_RAN_CPP" && ./a.out && rm a.out
        fi
    fi

    if $new; then
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

        $verbose && echo -e "Running: $abs_path\n\n"
        g++ "$abs_path" && ./a.out && rm a.out
    fi
}

bashrc() {
    local file="$HOME/.bashrc"

    if [[ ! -f "$file" ]]; then
        echo "Error: path \"$file\" does not point to a valid .bashrc file" >&2
        return 1
    fi

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
    shift

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

    ffmpeg -i "$input_file" "$@" -vcodec libx265 -crf 28 "$dir/compressed_$filename"
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
