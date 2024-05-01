# Load the zsh-autocomplete plugin
autoload -Uz compinit
compinit
source /path/to/zsh-autocomplete.plugin.zsh

# Define a function to fetch completions from the Python script
function fetch_completions {
    # Call the Python script and store the output in an array
    local -a suggestions
    suggestions=("${(@f)$(python3 autocomplete.py "$BUFFER" ".")}")

    # Output suggestions for zsh-autocomplete
    for suggestion in "${suggestions[@]}"; do
        echo "$suggestion"
    done
}

# Register the custom completion function
zstyle ':completion:*' completer _complete _approximate _autolist fetch_completions

# Bind the custom completion widget to Ctrl + Up Arrow
bindkey '^[[1;5A' _autocomplete
