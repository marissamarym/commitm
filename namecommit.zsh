commitm() {
    local system_prompt='Based on these changes, suggest a concise commit message, ideally less than 5 words:'
    local git_output_temp_file=$(mktemp)
    local commit_message_temp_file=$(mktemp)
    local cleaned_up=false # Flag to indicate whether cleanup has been run

    cleanup() {
        # Only run cleanup if it hasn't been done yet
        if [[ "$cleaned_up" == false ]]; then
            cleaned_up=true # Set the flag to prevent duplicate cleanup

            # Remove the temporary files if they exist
            [[ -f "$git_output_temp_file" ]] && rm "$git_output_temp_file"
            [[ -f "$commit_message_temp_file" ]] && rm "$commit_message_temp_file"

            # Reset the signal trap to the default behavior to clean up resources
            trap - SIGINT
        fi
    }

    # Set the trap for cleanup on SIGINT
    trap cleanup SIGINT

    # Check for staged changes to commit
    if ! git diff --cached --quiet; then
        # Capture the verbose dry-run output of git commit to a temp file
        git commit --dry-run -v > "$git_output_temp_file" 2>&1
    else
        echo "No changes staged for commit." >&2
        cleanup
        return 1
    fi

    # Process git commit dry-run output with llm, including the system prompt for better context.
    if ! llm -s "$system_prompt" < "$git_output_temp_file" > "$commit_message_temp_file" --no-stream; then
        echo "Error calling llm. Ensure llm is configured correctly and you have an active internet connection." >&2
        cleanup
        return 1
    fi

    # Check if the commit message was generated
    if [[ ! -s "$commit_message_temp_file" ]]; then
        echo "Failed to generate commit message." >&2
        cleanup
        return 1
    fi

    # Output the commit message and copy command to clipboard
    local commit_message=$(cat "$commit_message_temp_file")
    echo "Suggested commit message: $commit_message"
    local commit_command="git commit -m '$commit_message'"
    echo "$commit_command" | pbcopy

    echo "The commit command has been copied to your clipboard. You can paste it into your terminal to commit."

    # Perform cleanup
    cleanup
}
