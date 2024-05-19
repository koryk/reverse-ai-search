reverse_ai_search() {
  local input="$BUFFER"
  local index=1  # Corrected to 1-based index for Zsh
  local first=1
  local session_id=$(uuidgen)  # Generate a unique session ID
  local suggestions=("Type or press hotkey to fetch/cycle")
  local matched_suggestions=("${suggestions[@]}")
  local display_index=$((index))

  # Capture the current buffer and cursor position
  local orig_line=$BUFFER
  local orig_pos=$CURSOR

  # Create AISH_TEMP_DIR if it does not exist
  mkdir -p "$AISH_TEMP_DIR"

  while true; do
    display_index=$((index))
    echo -ne "\r\033[K(reverse-ai-search): '$input' |[${display_index}/${#matched_suggestions[@]}]| ${matched_suggestions[$index]}"

    if [[ $first -eq 1 ]]; then
      first=0
      IFS=$'\n' read -r -d '' -A suggestions <<< "$(python3 $AISH_PATH/autocomplete.py "$input" "$session_id" ".")"
      matched_suggestions=("${suggestions[@]}")
    fi

    # Read a single character and interpret it
    read -k1 key

    # Handle special keys
    case "$key" in
      $'\177')  # Backspace key
        if [[ -n $input ]]; then
          input=${input%?}
          index=1  # Reset to 1-based index for Zsh
          IFS=$'\n' read -r -d '' -A suggestions <<< "$(python3 $AISH_PATH/autocomplete.py "$input" "$session_id" ".")"
          matched_suggestions=("${suggestions[@]}")
        fi
        ;;
      $'\e')  # Escape key
        BUFFER=$orig_line
        CURSOR=$orig_pos
        echo -e "\033[?25h"
        return 0
        ;;
      $'\n'|$'\r')  # Enter key to select suggestion
        BUFFER="${matched_suggestions[$index]}"
        CURSOR=${#BUFFER}
        zle redisplay
        return 0
        ;;
      $AISH_HOTKEY)  # Custom hotkey to cycle through suggestions
        if (( index >= ${#matched_suggestions[@]} )); then
          index=1  # Cycle back to start
        else
          index=$((index + 1))
        fi
        ;;
      *)
        input+="$key"
        index=1  # Reset to 1-based index for Zsh
        IFS=$'\n' read -r -d '' -A suggestions <<< "$(python3 $AISH_PATH/autocomplete.py "$input" "$session_id" ".")"
        matched_suggestions=("${suggestions[@]}")
        ;;
    esac
  done
}
