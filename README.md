# Ollama LLM CLI completion similar to `reverse-i-search`
Integrate AI into bash in a way you already use, with `ctrl+r` aka `reverse-ai-search`

Reverse AI Search provides local AI bash completion in a format you're already familiar with.

# Use Cases

## Command creation

```
# find all yaml files
(reverse-ai-search): '#find all yaml files' find . -name '*.yaml'
$ find . -name '*.yaml'
```

## Fix mispelling 

```
(reverse-ai-search): 'suod vmi /ect/hots' sudo vim /etc/hosts
kigu@pop-os:~/dev/zsh-ollama-autocomplete$ sudo vim /etc/hosts
```

## Command completion

```
(reverse-ai-search): 'curl localhost | jq #last item in values array' curl localhost | jq '.values | last'
kigu@pop-os:~/dev/zsh-ollama-autocomplete$ curl localhost | jq '.values | last'
```

# Requirements

- ollama - codegemma or codellama models
- python3

# Add to .bashrc or .zshrc

```
bind -x '"\C-o": "reverse_ai_search"'
export AISH_TEMP_DIR="/tmp/reverse_ai_search"
export AISH_PATH="/path/to/codebase"
export AISH_HOTKEY=${AISH_HOTKEY:-'0f'}  
source $AISH_PATH/autocomplete.sh
```

# Configuration (Optional)

Configuration values with their defaults

```

# temporary directory for caching lookup
AISH_TEMP_DIR=/tmp/reverse_ai_search

# Ollama model to use
AISH_OLLAMA_MODEL=codegemma

# Ollama host string
AISH_OLLAMA_HOST=http://localhost:11434
```

# TODO
- send buffer to LLM every keystroke. Otherwise is sent on function call. `AISH_STREAM_RESULTS=1`
- incorporate the directory into the prompt
- prompt tuning
- fine-tuned model

# Other notes

- It caches results for strings in the temp directory, so you may want to clear these for many reasons.
- There is an attempt to rate limit the number of predictions sent to ollama per session. If you are experiencing slowness disable `AISH_STREAM_RESULTS` and use the key bind to initialize ai search.
