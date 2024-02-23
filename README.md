# commitm - AI-Generated Git Commit Messages

Use the `commitm` command to generate commit messages, modify them, and commit!

![CleanShot 2024-02-21 at 16 14 29@2x](https://github.com/marissamarym/homebrew-commitm/assets/1459660/c98e14d5-bbac-4562-9d4e-4e5ed906a800)

Inspired by [my brother Adam's AI Shell Command Generator](https://gist.github.com/montasaurus/5ccbe453ef863f702291e763b1b63daf) ([tweet](https://twitter.com/montasaurus_rex/status/1758506549478097383)).

## Features

- Generates commit messages using the `llm` CLI based on staged changes
- Allows modifying messages to be more general, specific, longer, shorter etc
- Commits generated messages (with the prefix 🤖) or custom messages

## Getting Started

### Prerequisites

Install and configure the [llm](https://llm.datasette.io/en/stable/#quick-start) CLI tool. `llm` needs an API key (like the OpenAI API key) to make LLM calls.

### Installation

#### Option 1: With Homebrew

```bash
brew install commitm
```

#### Option 2: From Repo

Clone this repository to your desired location:

```bash
git clone https://github.com/marissamarym/commitm.git
```

To make the script easily accessible from anywhere, add the following alias to your .zshrc file:

```bash
echo 'alias commitm="$HOME/path/to/commitm/src/commitm.zsh"' >> ~/.zshrc
```

Replace `$HOME/path/to/commitm` with the actual path to where you cloned or placed `commitm`.

Apply the changes to your `.zshrc` by running:

```bash
source ~/.zshrc
```

## Usage

To generate a commit message:

```bash
commitm
```

To generate a commit message and commit it immediately:

```bash
commitm -e
```

To generate a commit message with a custom prefix (default is 🤖):

```bash
commitm -p ✨
```

To generate a commit message without a custom prefix (default is 🤖):

```bash
commitm --no-prefix
```

To generate a commit message and commit immediately without showing output:

```bash
commitm -e -q
```

## Caveats

- `commitm` limits the prompt to 4096 tokens.

## Contributing

Any contributions you make are greatly appreciated.

## License

Distributed under the MIT License. See LICENSE for more information.
