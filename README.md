# AI Git Commit Message Generator using [LLM](https://llm.datasette.io/en/stable/)

Inspired by [my brother Adam's AI Shell Command Generator](https://gist.github.com/montasaurus/5ccbe453ef863f702291e763b1b63daf) ([tweet](https://twitter.com/montasaurus_rex/status/1758506549478097383)).

- Runs `git commit --dry-run -v` to get a summary of your staged changes.
- Prompts `llm` to generate a commit message.
- Asks if you want to commit the message or modify it (make it shorter, longer, more detailed, or more general).

## Usage

To generate a commit message:

```bash
commitm
```

To generate a commit message and commit it immediately:

```bash
commitm -e
```

## Installation

Install and configure the [llm](https://llm.datasette.io/en/stable/#quick-start) CLI tool. Add the `commitm` function to your `.zshrc`.
