# autocomplete.py

# Set up the data payload for the POST request
prompt = """You are an expert at using the terminal like bash/zsh.

Provide only bash suggestions for the current terminal buffer.

Only respond with valid bash/zsh commands

Your commands must be surrounded by ```

### Example 1:
**Buffer**: `find . -name ...video files?`
  
suggest:
```
find . -type f \( -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" \) 2>/dev/null
find . -type f -regex ".*\.\(mp4\|avi\|mov\)$" 2>/dev/null
find . -type f -name "*.*" -exec file {} + | grep -i "video"
```

### Example 2:
**Buffer**: `suod vmi /ect/hots`
  
suggest:
```
sudo vim /etc/hosts
sudo vi /etc/hosts
sudo nano /etc/hosts
```

### Example 3:
**Buffer**: `#find a directory named dave`
  
suggest:
```
find / -type d -name "dave" 2>/dev/null
locate /dave/ | grep -E "/dave$"
find ~ -type d -iname "*dave*" -print
```

### User input:
"""
import sys
import requests
import json
import hashlib
import os
import time

CACHE_DIR = os.environ.get("AISH_TEMP_DIR", "/tmp/")

def get_cache_path(prompt, buffer):
    """Generate a file path for caching based on a hash of the combined prompt and buffer."""
    combined_input = prompt + buffer
    hash_object = hashlib.md5(combined_input.encode())
    hash_digest = hash_object.hexdigest()
    return f"{CACHE_DIR}autocomplete_cache_{hash_digest}.txt"

def get_session_cache_path(session_id):
    """Generate a session-specific cache path."""
    return f"{CACHE_DIR}session_cache_{session_id}.txt"

def fetch_completions(prompt, buffer):
    """Fetch completions from the API and cache the result."""
    model = os.environ.get("AISH_OLLAMA_MODEL", "codegemma")
    data = {
        "model": model,
        "prompt": prompt + buffer + "suggest:\n"
    }
    host = os.environ.get("AISH_OLLAMA_HOST", "http://localhost:11434")
    url = f"{host}/api/generate"
    response = requests.post(url, json=data)
    response.raise_for_status()

    complete_response = ""
    for line in response.iter_lines():
        if line:
            json_response = json.loads(line)
            complete_response += json_response["response"]
            if json_response["done"]:
                break

    # Cache the complete response
    cache_path = get_cache_path(prompt, buffer)
    with open(cache_path, 'w') as file:
        if "```" in complete_response:
            cached_response = complete_response
            if "suggest:" in cached_response:
                cached_response = cached_response.replace("suggest:", "")
            if ('```' in cached_response):
                cached_response = cached_response.split("```")[1]
            final = cached_response
            final = "\n".join(final.replace('```\n', '').replace("\n\n", "\n").split("\n")[0:3])
            file.write(final)
        else:
            return None

    return final

def get_completions(prompt, buffer, session_id):
    """Retrieve completions from cache or fetch new ones if cache does not exist."""
    cache_path = get_cache_path(prompt, buffer)
    session_cache_path = get_session_cache_path(session_id)
    current_time = int(time.time() * 1000)  # Current time in milliseconds

    # Check if a fetch is necessary based on the last fetch timestamp
    try:
        with open(session_cache_path, 'r') as file:
            last_fetch_time, last_result = file.readline().strip(), file.read()
            if (current_time - int(last_fetch_time)) < 500:  # Less than 250 ms since last fetch
                return last_result  # Return cached results if available
    except FileNotFoundError:
        pass  # No cache found, proceed with fetching

    if os.path.exists(cache_path):
        with open(cache_path, 'r') as file:
            return file.read()
    else:
        return fetch_completions(prompt, buffer)

if __name__ == "__main__":
    buffer = sys.argv[1]
    session_id = sys.argv[2]
    directory = sys.argv[3]
    # Prompt is assumed to be defined elsewhere, before running the script
    print(get_completions(prompt, buffer, session_id))
