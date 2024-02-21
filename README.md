# AI Git Commit Message Generator

Use the `commitm` command to generate commit messages, modify them, and commit!

![CleanShot 2024-02-21 at 16 16 50@2x](https://github.com/marissamarym/commitm/assets/1459660/b1a3b0b5-7728-415b-8a17-28d72291ec60)


Inspired by [my brother Adam's AI Shell Command Generator](https://gist.github.com/montasaurus/5ccbe453ef863f702291e763b1b63daf) ([tweet](https://twitter.com/montasaurus_rex/status/1758506549478097383)).

The `commitm` command:

- Runs `git commit --dry-run -v` to get a summary of your staged changes.
- Prompts `llm` to generate a commit message.
- Asks if you want to commit the message, modify it (make it shorter, longer, more detailed, or more general), or enter a custom message.

## Getting Started

### Prerequisites

Install and configure the [llm](https://llm.datasette.io/en/stable/#quick-start) CLI tool.

### Installation

#### Option 1: With Homebrew

```bash
brew install marissamarym/commitm/commitm
```

Or

```bash
brew tap marissamarym/commitm
```

and then

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

## Contributing

Any contributions you make are greatly appreciated.

## License

Distributed under the MIT License. See LICENSE for more information.
