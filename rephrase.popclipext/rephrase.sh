#!/bin/bash
# #popclip
# name: Rephrase

word="$POPCLIP_TEXT"
API_KEY="${POPCLIP_OPTION_API_KEY}"

# Log debug info
# env > /tmp/popclip_debug.log
# echo "Starting script for word: $word" >> /tmp/popclip_debug.log

if [ -z "$API_KEY" ]; then
    # echo "Error: API_KEY is not set." >> /tmp/popclip_debug.log
    exit 2  # Triggers PopClip settings dialog
fi

get_synonyms() {
    response=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "{
      \"model\": \"gpt-4o\",
      \"messages\": [
        {
          \"role\": \"system\",
          \"content\": \"You are an assistant that provides structured outputs strictly adhering to the provided schema.\"
        },
        {
          \"role\": \"user\",
          \"content\": \"Provide 5 synonyms or alternative expressions for \\\"$word\\\". Make sure your answer fits the provided schema.\"
        }
      ],
      \"response_format\": {
        \"type\": \"json_schema\",
        \"json_schema\": {
          \"name\": \"synonyms_list\",
          \"schema\": {
            \"type\": \"object\",
            \"properties\": {
              \"word\": {\"type\": \"string\"},
              \"synonyms\": {\"type\": \"string\"}
            },
            \"required\": [\"word\", \"synonyms\"],
            \"additionalProperties\": false
          }
        }
      }
    }")

    # echo "Raw API Response: $response" >> /tmp/popclip_debug.log

    content=$(echo "$response" | jq -r '.choices[0].message.content // empty')
    if [ -z "$content" ]; then
        # echo "Error: Empty content from API." >> /tmp/popclip_debug.log
        echo "$word"  # Fallback to original word
        exit 1
    fi

    synonyms=$(echo "$content" | jq -r '.synonyms // empty')
    if [ -z "$synonyms" ]; then
        # echo "Error: Synonyms field is empty." >> /tmp/popclip_debug.log
        echo "$word"  # Fallback to original word
        exit 1
    fi

    
    # Remove extra spaces around commas
    clean_synonyms=$(echo "$synonyms" | sed 's/, */,/g')
    echo "$clean_synonyms"

}

# Retrieve synonyms and use AppleScript for selection
synonyms=$(get_synonyms | tr ',' '\n')
if [ -z "$synonyms" ]; then
    # echo "Error: Failed to retrieve synonyms." >> /tmp/popclip_debug.log
    exit 1
fi

# Use AppleScript for dropdown selection
selected_synonym=$(osascript <<EOF
set synonyms to paragraphs of "$synonyms"
set chosenWord to (choose from list synonyms with title "Choose a synonym" with prompt "Pick replacement for '$word':" default items {item 1 of synonyms})
if chosenWord is false then
    return "$word"
else
    return item 1 of chosenWord
end if
EOF
)

# Fallback if no selection is made
if [ -z "$selected_synonym" ]; then
    selected_synonym="$word"
fi

# echo "Final replacement: $selected_synonym" >> /tmp/popclip_debug.log

# Copy the replacement to clipboard
echo -n "$selected_synonym" | pbcopy

# Emulate Cmd+V
osascript <<EOF
tell application "System Events"
    keystroke "v" using command down
end tell
EOF

exit 0
