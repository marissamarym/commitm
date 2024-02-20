#!/bin/zsh


commitm() {
    local system_prompt='Based on these changes, suggest a concise commit message, without any quotations around it, that is '
    local prompt_modification='less than 5 words'
    local execute_commit=false
    local git_output_temp_file=$(mktemp)
    local commit_message_temp_file=$(mktemp)
    local commit_message=''
    local cleaned_up=false # Flag to indicate whether cleanup has been run
    local length_level=0
    
    # Check for the execute flag (-e)
    if [[ "$1" == "--execute" ]] || [[ "$1" == "-e" ]]; then
        execute_commit=true
    fi

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
        commit_message_length=${#commit_message}
        case $1 in
            l) 
                if [[ $length_level -ge 2 ]]; then
                    echo "Commit message cannot be longer."
                    return 1
                fi
                length_level=$((length_level+1))
                prompt_modification="longer than $commit_message_length characters"
                ;;
            s) 
                if [[ $length_level -le -2 ]]; then
                    echo "Commit message cannot be shorter."
                    return 1
                fi
                length_level=$((length_level-1))
                prompt_modification="shorter than $commit_message_length characters"
                ;;
            d) prompt_modification="more detailed than $commit_message";;
            g) prompt_modification="more general than $commit_message";;
            *) echo "Invalid option"; return 1;;
        esac

        generate_commit_message
        echo "Modified commit message: \e[1m\e[34m$(cat "$commit_message_temp_file")\e[0m"
    }

    generate_commit_message() {
        # Read the content of the git output temp file
        local git_changes=$(cat "$git_output_temp_file")
        
        # Prepare the system prompt with modifications and git changes
        local system_prompt_mod="$system_prompt$prompt_modification"
        local git_changes_formatted="Git changes:\n\`\`\`\n$git_changes\n\`\`\`"

        # Combine the system prompt and the git changes for llm's input
        local full_prompt="$system_prompt_mod: $git_changes_formatted"
        
        # Process git commit dry-run output with llm, including the system prompt for better context.
        if ! echo "$full_prompt" | llm -s "$system_prompt_mod" --no-stream > "$commit_message_temp_file"; then
            echo "Error calling llm. Ensure llm is configured correctly and you have an active internet connection." >&2
            cleanup
            return 1
        fi
    }

    generate_commit_message

    # Check if the commit message was generated
    if [[ ! -s "$commit_message_temp_file" ]]; then
        echo "Failed to generate commit message." >&2
        cleanup
        return 1
    fi

    commit_message=$(cat "$commit_message_temp_file")
    echo -e "Generated commit message: \e[1m\e[34m$commit_message\e[0m\n"


    # Main loop for user decisions
    while true; do
        echo -e "Do you want to commit with this message? (y/n/l/s/d/g/c)"
        read user_decision

        if [[ "$user_decision" =~ ^[Yy]$ ]]; then
            git commit -m "$(cat "$commit_message_temp_file")"
            break
        elif [[ "$user_decision" == "n" ]]; then
            echo "Commit aborted by user."
            break
        elif [[ "$user_decision" == "c" ]]; then
            # add user input as commit message
            echo "Enter your custom commit message:"
            read custom_commit_message
            echo "$custom_commit_message" > "$commit_message_temp_file"

            echo -e "Generated commit message: \e[1m\e[34m$custom_commit_message\e[0m\n"
            echo -e "Do you want to commit with this message? (y/n)"

            read user_decision
            if [[ "$user_decision" =~ ^[Yy]$ ]]; then
                git commit -m "$(cat "$commit_message_temp_file")"
                break
            elif [[ "$user_decision" == "n" ]]; then
                echo "Commit aborted by user."
                break
            else
                echo "Invalid option. Please enter y or n."
            fi


            break
        elif [[ "$user_decision" =~ ^[lsdgc]$ ]]; then
            modify_prompt "$user_decision"
        else
            echo "Invalid option. Please enter y, n, l, s, d, g, or c."
        fi
    done
    
    # if [[ "$execute_commit" == true ]]; then
    #     # Execute the git commit command with the generated message if the execute flag is set
    #     git commit -m "$commit_message"
    # else
    #     # Output the commit message and copy command to clipboard
    #     local commit_command="git commit -m '$commit_message'"
    #     echo "$commit_command" | pbcopy
    #     echo "The commit command has been copied to your clipboard. You can paste it into your terminal to commit."
    # fi
    
    # Perform cleanup
    cleanup
}

commitm