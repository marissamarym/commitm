#!/bin/zsh

show_help() {
    echo "Usage: commitm [OPTIONS]"
    echo ""
    echo "Generate commit messages with AI."
    echo ""
    echo "Options:"
    echo "  -e, --execute      Execute the git commit with the generated message."
    echo "  -h, --help         Show this help message."
    echo "  -p, --prefix       Change the prefix of the generated message from the default of 🤖."
    echo "  -np, --no-prefix   Clear the prefix for the generated message."
    echo "  -v                 Show the current version."
    echo "  -q, --quiet        Suppress all output."
}

show_version() {
    echo "commitm v1.0.5"
}

show_error() {
    echo -e "\e[31mError: $1\e[0m" >&2
}

show_warning() {
    echo -e "\e[33mWarning: $1\e[0m" >&2
}

show_echo() {
    if [[ "$suppress_output" == false ]]; then
        echo -e "$1"
    fi
}

commitm() {
    local prefix="🤖" # Default prefix
    local use_prefix=true
    local suppress_output=false
    local system_prompt="Based on these changes, suggest a good commit message, \
        without any quotations around it or a period at the end. \
        Keep it concise and to the point. \
        If the diff only changes comments, the commit message should say something to that effect. \
        Avoid filler words or flowery/corporate language like 'refine'. It should be "
    local prompt_mod="less than 5 words"
    local execute_commit=false
    local git_output_temp_file=$(mktemp)
    local commit_message_temp_file=$(mktemp)
    local commit_message=""
    local cleaned_up=false
    local length_level=0
    local is_bot_generated=true

    # Command line argument validation
    local is_prefix_set=false
    local is_no_prefix_set=false
    for arg in "$@"; do
        if [[ "$arg" == "--prefix" ]] || [[ "$arg" == "-p" ]]; then
            is_prefix_set=true
        elif [[ "$arg" == "--no-prefix" ]] || [[ "$arg" == "-np" ]]; then
            is_no_prefix_set=true
        fi
    done

    if [[ "$is_prefix_set" == true ]] && [[ "$is_no_prefix_set" == true ]]; then
        show_error "--prefix and --no-prefix cannot be used together."
        return 1
    fi

    # Parse the command line arguments
    for arg in "$@"; do
        if [[ "$prev_arg" == "--prefix" ]] || [[ "$prev_arg" == "-p" ]]; then
            prefix="$arg"
            # Reset prev_arg
            prev_arg=""
            continue
        fi
        prev_arg="$arg"
        
        if [[ "$arg" == "--execute" ]] || [[ "$arg" == "-e" ]]; then
            execute_commit=true
        elif [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
            show_help
            return 0
        elif [[ "$arg" == "-v" ]]; then
            show_version
            return 0
        elif [[ "$arg" == "--no-prefix" ]] || [[ "$arg" == "-np" ]]; then
            use_prefix=false
        elif [[ "$arg" == "-q" ]] || [[ "$arg" == "--quiet" ]]; then
            suppress_output=true
        fi
    done

    # Execute the commit with the commit message
    make_commit() {
        local commit_msg_format="%s"
        if [[ "$is_bot_generated" == true ]] && [[ "$no_prefix" != true ]]; then
            git commit -m "$(printf '%s %s' "$prefix" "$(cat "$commit_message_temp_file")")"
        else
            git commit -m "$(printf '%s' "$(cat "$commit_message_temp_file")")"
        fi
    }

    # Handle user input for modifying the commit message prompt
    modify_prompt() {
        commit_message_length=${#commit_message}
        case $1 in
            l) 
                if [[ $length_level -ge 1 ]]; then
                    show_warning "Commit message cannot be longer."
                else
                    length_level=$((length_level+1))
                    prompt_mod="longer than $commit_message_length characters"
                fi
                ;;
            s) 
                if [[ $length_level -le -1 ]]; then
                    show_warning "Commit message cannot be shorter."
                else
                    length_level=$((length_level-1))
                    prompt_mod="shorter than $commit_message_length characters"
                fi
                ;;
            d) prompt_mod="more detailed and specific in regards to the contents of the lines changed than $commit_message";;
            g) prompt_mod="more general than $commit_message";;
            *) show_error "Invalid option"; return 1;;
        esac

        generate_commit_message

        local prompt_mod_description=''
        case $1 in
            l) prompt_mod_description="Longer";;
            s) prompt_mod_description="Shorter";;
            d) prompt_mod_description="More detailed";;
            g) prompt_mod_description="More general";;
        esac

        show_echo -e "\n$prompt_mod_description prompt: \e[1m\e[36m$(cat "$commit_message_temp_file")\e[0m\n"
    }

    # Generate the commit message with llm
    generate_commit_message() {
        is_bot_generated=true
        # Read the content of the git output temp file
        local git_changes=$(cat "$git_output_temp_file")
        
        # Prepare the system prompt with modifications and git changes
        local full_system_prompt="$system_prompt$prompt_mod"
        local git_changes_formatted="$git_changes"


        # Combine the system prompt and the git changes for llm's input
        local user_prompt="$git_changes_formatted"

        # Use ttok to truncate the input to 4096 tokens (GPT 3.5 turbo max token limit)
        local max_tokens=4096
        local token_buffer=10
        local system_prompt_length=$(echo "$full_system_prompt" | ttok)
        local user_prompt_allowed_length=$((max_tokens - system_prompt_length - token_buffer))
        local truncated_user_prompt=$(echo "$user_prompt" | ttok -t $user_prompt_allowed_length)
        
        # Process git commit dry-run output with llm, including the system prompt for better context.
        if ! echo "$truncated_user_prompt" | llm -s "$full_system_prompt" --no-stream > "$commit_message_temp_file"; then
            show_error "Error calling llm. Ensure llm is configured correctly and you have an active internet connection."
            cleanup
            return 1
        fi
    }

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
        show_warning "No changes staged for commit."
        cleanup
        return 1
    fi

    generate_commit_message

    # Check if the commit message was generated
    if [[ ! -s "$commit_message_temp_file" ]]; then
        show_error "Failed to generate commit message."
        cleanup
        return 1
    fi

    commit_message=$(cat "$commit_message_temp_file")
    
    show_echo "Generated commit message: \e[1m\e[36m$commit_message\e[0m\n"

    # Commit immediately if the execute flag is set
    if [[ "$execute_commit" == true ]]; then
        make_commit
        return 0
    fi

    # Main loop for user decisions
    while true; do

    
    if [[ "$suppress_output" == false ]]; then
        # Explain options: yes, no, longer, shorter, detailed, general, custom
        show_echo "Do you want to commit with this message? (\e[32my\e[0m/\e[31mn\e[0m/l/s/d/g/c)"
        show_echo "\e[32my\e[0m: yes"
        show_echo "\e[31mn\e[0m: no"
        show_echo "l: longer"
        show_echo "s: shorter"
        show_echo "d: more detailed"
        show_echo "g: more general"
        show_echo "c: custom"
    fi

        read user_decision

        if [[ "$user_decision" =~ ^[Yy]$ ]]; then
            make_commit
            break
        elif [[ "$user_decision" == "n" ]]; then
            show_echo "Commit aborted by user."
            break
        elif [[ "$user_decision" == "c" ]]; then
            is_bot_generated=false
            # Add user input as commit message
            show_echo "Enter your custom commit message:\n"
            read custom_commit_message
            show_echo "$custom_commit_message" > "$commit_message_temp_file"

            show_echo "Your commit message: \e[1m\e[36m$custom_commit_message\e[0m\n"
            show_echo "Do you want to commit with this message? (y/n)"

            read user_decision
            if [[ "$user_decision" =~ ^[Yy]$ ]]; then
                make_commit
                break
            else
                show_echo "Commit aborted by user."
                break
            fi


            break
        elif [[ "$user_decision" =~ ^[lsdgc]$ ]]; then
            modify_prompt "$user_decision"
        else
            show_echo "Invalid option. Please enter y, n, l, s, d, g, or c."
        fi
    done
    
    # Perform cleanup
    cleanup
}

commitm "$@"