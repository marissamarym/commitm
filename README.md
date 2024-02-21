# AI Git Commit Message Generator using [llm](https://llm.datasette.io/en/stable/)

Inspired by [my brother Adam's AI Shell Command Generator](https://gist.github.com/montasaurus/5ccbe453ef863f702291e763b1b63daf) ([tweet](https://twitter.com/montasaurus_rex/status/1758506549478097383)).

- Runs `git commit --dry-run -v` to get a summary of your staged changes.
- Prompts `llm` to generate a commit message.
- Asks if you want to commit the message or modify it (make it shorter, longer, more detailed, or more general).

## Getting Started

### Prerequisites

Install and configure the [llm](https://llm.datasette.io/en/stable/#quick-start) CLI tool.

### Installation

Clone this repository to your desired location:

```bash
git clone https://github.com/marissamarym/commitm.git
```

To make the script easily accessible from anywhere, add the following alias to your .zshrc file:

```bash
echo 'alias commitm="$HOME/path/to/commitm/src/commitm.zsh"' >> ~/.zshrc
```

Replace $HOME/path/to/commitm with the actual path to where you cloned or placed commitm.

Apply the changes to your .zshrc by running:

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
