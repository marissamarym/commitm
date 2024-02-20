#!/bin/zsh


commitm() {
    local system_prompt="Based on these changes, suggest a good commit message, \
        without any quotations around it or a period at the end. \
        Keep it concise and to the point. \
        Avoid filler words or flowery/corporate language like 'refine'. It should be "
    local prompt_modification='less than 5 words'
    local execute_commit=false
    local git_output_temp_file=$(mktemp)
    local commit_message_temp_file=$(mktemp)
    local commit_message=''
    local cleaned_up=false # Flag to indicate whether cleanup has been run
    local length_level=0
    local is_bot_generated=true
    
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


    make_commit() {
        if [[ "$is_bot_generated" == true ]]; then
            git commit -m "$(printf '🤖 %s' "$(cat "$commit_message_temp_file")")"
        else
            git commit -m "$(printf '%s' "$(cat "$commit_message_temp_file")")"
        fi
    }

    # Function to handle user input for modifying the commit message prompt
    modify_prompt() {
        commit_message_length=${#commit_message}
        case $1 in
            l) 
                if [[ $length_level -ge 2 ]]; then
                    echo "Commit message cannot be longer."
                    break
                fi
                length_level=$((length_level+1))
                prompt_modification="longer than $commit_message_length characters"
                ;;
            s) 
                if [[ $length_level -le -2 ]]; then
                    echo "Commit message cannot be shorter."
                    break
                fi
                length_level=$((length_level-1))
                prompt_modification="shorter than $commit_message_length characters"
                ;;
            d) prompt_modification="more detailed and specific in regards to the contents of the lines changed than $commit_message";;
            g) prompt_modification="more general than $commit_message";;
            *) echo "Invalid option"; return 1;;
        esac

        generate_commit_message
        echo "Modified commit message: \e[1m\e[34m$(cat "$commit_message_temp_file")\e[0m"
    }

    generate_commit_message() {
        is_bot_generated=true
        # Read the content of the git output temp file
        local git_changes=$(cat "$git_output_temp_file")
        
        # Prepare the system prompt with modifications and git changes
        local full_system_prompt="$system_prompt$prompt_modification"
        local git_changes_formatted="$git_changes"

        # Combine the system prompt and the git changes for llm's input
        local user_prompt="$git_changes_formatted"
        
        # Process git commit dry-run output with llm, including the system prompt for better context.
        if ! echo "$user_prompt" | llm -s "$full_system_prompt" --no-stream -m gpt-4-turbo > "$commit_message_temp_file"; then
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

    # commit immediately if the execute flag is set
    if [[ "$execute_commit" == true ]]; then
        make_commit
        return 0
    fi

    # Main loop for user decisions
    while true; do
        echo -e "Do you want to commit with this message? (y/n/l/s/d/g/c)"
        read user_decision

        if [[ "$user_decision" =~ ^[Yy]$ ]]; then
            make_commit
            break
        elif [[ "$user_decision" == "n" ]]; then
            echo "Commit aborted by user."
            break
        elif [[ "$user_decision" == "c" ]]; then
            is_bot_generated=false
            # add user input as commit message
            echo "Enter your custom commit message:"
            read custom_commit_message
            echo "$custom_commit_message" > "$commit_message_temp_file"

            echo -e "Your commit message: \e[1m\e[34m$custom_commit_message\e[0m\n"
            echo -e "Do you want to commit with this message? (y/n)"

            read user_decision
            if [[ "$user_decision" =~ ^[Yy]$ ]]; then
                make_commit
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
    
    # Perform cleanup
    cleanup
}

commitm