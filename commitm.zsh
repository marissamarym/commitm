#!/bin/zsh

commitm() {
    local system_prompt='Based on these changes, suggest a concise commit message, ideally less than 5 words:'
    local git_output_temp_file=$(mktemp)
    local commit_message_temp_file=$(mktemp)
    local cleaned_up=false # Flag to indicate whether cleanup has been run
    local prompt_modification=''

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

    # Function to handle user input for modifying the commit message prompt
    modify_prompt() {
        case $1 in
            l) prompt_modification=' longer';;
            s) prompt_modification=' shorter';;
            d) prompt_modification=' more detailed';;
            g) prompt_modification=' more general';;
            c) 
              echo "Enter your custom prompt modification:"
              read custom_mod
              prompt_modification=" $custom_mod"
              ;;
            *) echo "Invalid option"; return 1;;
        esac
    }

    # Generate commit message with initial prompt
    generate_commit_message() {
        # Process git commit dry-run output with llm, including the system prompt for better context.
        if ! llm -s "$system_prompt$prompt_modification" < "$git_output_temp_file" > "$commit_message_temp_file" --no-stream; then
            echo "Error calling llm. Ensure llm is configured correctly and you have an active internet connection." >&2
            cleanup
            return 1
        fi
    }

    local commit_message=$(cat "$commit_message_temp_file")
    echo $commit
    echo "Generated commit message: \e[1m\e[34m$(cat "$commit_message_temp_file")\e[0m"
    generate_commit_message

    # Main loop for user decisions
    while true; do
        echo -e "\nDo you want to commit with this message? (Y/n/l/s/d/g/c)"
        read user_decision

        if [[ "$user_decision" =~ ^[Yy]$ ]]; then
            git commit -m "$(cat "$commit_message_temp_file")"
            break
        elif [[ "$user_decision" == "n" ]]; then
            echo "Commit aborted by user."
            break
        elif [[ "$user_decision" =~ ^[lsdgc]$ ]]; then
            modify_prompt "$user_decision"
            generate_commit_message
            echo "Modified commit message: \e[1m\e[34m$(cat "$commit_message_temp_file")\e[0m"
        else
            echo "Invalid option. Please enter Y, n, l, s, d, g, or c."
        fi
    done

    # Perform cleanup
    cleanup
}

commitm