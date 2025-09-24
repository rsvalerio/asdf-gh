<div align="center">

# asdf-gh [![Build](https://github.com/rsvalerio/asdf-gh/actions/workflows/build.yml/badge.svg)](https://github.com/rsvalerio/asdf-gh/actions/workflows/build.yml) [![Lint](https://github.com/rsvalerio/asdf-gh/actions/workflows/lint.yml/badge.svg)](https://github.com/rsvalerio/asdf-gh/actions/workflows/lint.yml)

[GitHub CLI (gh)](https://cli.github.com/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [About](#about)
- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# About

GitHub CLI (gh) is a command-line tool for GitHub operations and workflows. This plugin allows you to manage different versions of GitHub CLI using asdf.

With GitHub CLI, you can:
- Work with GitHub issues, pull requests, and releases
- Manage repositories and organizations
- Authenticate with GitHub
- Run GitHub Actions workflows
- Create and manage gists
- Clone repositories with authentication
- Integrate with your development workflow

For more information, visit [cli.github.com](https://cli.github.com/).

# Dependencies

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- Supported platforms: macOS (ARM64 and AMD64) and Linux (AMD64)

# Install

Plugin:

```shell
asdf plugin add gh
# or
asdf plugin add gh https://github.com/rsvalerio/asdf-gh.git
```

GitHub CLI:

```shell
# Show all installable versions
asdf list-all gh

# Install specific version
asdf install gh latest

# Set a version globally (on your ~/.tool-versions file)
asdf global gh latest

# Now gh commands are available
gh --version

# Authenticate with GitHub
gh auth login
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/rsvalerio/asdf-gh/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Rodrigo Valeri](https://github.com/rsvalerio/)
