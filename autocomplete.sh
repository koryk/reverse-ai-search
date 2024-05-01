#!/bin/bash

reverse_ai_search() {
  local input="$READLINE_LINE"
  local index=0
  local first=1
  local session_id=$(uuidgen)  # Generate a unique session ID
  local suggestions=("Type or press hotkey to fetch/cycle")
  local matched_suggestions=("${suggestions[@]}")

  # Capture the current buffer and cursor position
  local orig_line=$READLINE_LINE
  local orig_pos=$READLINE_POINT
  
  # Create AISH_TEMP_DIR if it does not exist
  mkdir -p "$AISH_TEMP_DIR"

  while :; do
    display_index=$((index + 1))
    echo -ne "\r\033[K(reverse-ai-search): '$input' |[${display_index}/${#matched_suggestions[@]}]| ${matched_suggestions[$index]}"
    
    if [[ $first -eq 1 ]]; then
      first=0
      IFS=$'\n' read -d '' -ra suggestions <<< "$(python3 $AISH_PATH/autocomplete.py "$input" "$session_id" ".")"
      matched_suggestions=("${suggestions[@]}")
    fi
    
    IFS= read -rsn1 key
    local key_code=$(printf "%s" "$key" | xxd -p | tr -d '\n')

    if [[ -z "$key_code" ]]; then
        READLINE_LINE="${matched_suggestions[$index]}"
        READLINE_POINT=${#READLINE_LINE}
        echo -e "\033[?25h"
        break
    fi
    
    case $key_code in
      '7f')
        [[ -n $input ]] && input=${input%?}
        index=0
        ;;
      '1b')
        READLINE_LINE=$orig_line
        READLINE_POINT=$orig_pos
        echo -e "\033[?25h"
        break
        ;;
      "$AISH_HOTKEY")
        if [[ $index+1 -ge ${#matched_suggestions[@]} ]]; then
          index=-1
        fi
        index=$((index + 1))
        continue
        ;;
      *)
        input+="$key"
        index=0
        IFS=$'\n' read -d '' -ra suggestions <<< "$(python3 $AISH_PATH/autocomplete.py "$input" "." "$session_id")"
        matched_suggestions=("${suggestions[@]}")
        ;;
    esac
  done
}
