# GitHub CLI (gh) asdf Plugin Design Document

## Overview

This document outlines the design and implementation plan for creating an asdf plugin to manage GitHub CLI installations. The plugin will support downloading, installing, and managing different versions of the GitHub CLI binary for macOS (both ARM64 and AMD64 architectures) and Linux.

## Plugin Name and Repository

- **Plugin Name**: `gh` (GitHub CLI)
- **Repository**: `asdf-gh`
- **GitHub URL**: `https://github.com/rsvalerio/asdf-gh`
- **Reference Plugin**: `https://github.com/bartlomiejdanek/asdf-github-cli`

## Initial Setup Steps

### 1. Generate Plugin from Template

Use the asdf plugin template to create the initial plugin structure:

```bash
# Navigate to GitHub template generation page
# https://github.com/asdf-vm/asdf-plugin-template/generate

# Or clone the template directly
git clone https://github.com/asdf-vm/asdf-plugin-template.git asdf-gh
cd asdf-gh

# Run the setup script to customize the template
./setup.bash
```

### 2. Template Customization

When running `setup.bash`, provide the following information:
- **Plugin name**: `gh`
- **Tool name**: `GitHub CLI`
- **Tool description**: `Command-line tool for GitHub operations and workflows`
- **GitHub repository**: `https://github.com/cli/cli`
- **Homepage**: `https://cli.github.com/`

### 3. Initial File Replacements

After template generation, perform these replacements across all files:

```bash
# Replace template placeholders with gh-specific values
find . -type f -name "*.bash" -o -name "*.md" -o -name "*.yml" | xargs sed -i '' 's/{{PLUGIN_NAME}}/gh/g'
find . -type f -name "*.bash" -o -name "*.md" -o -name "*.yml" | xargs sed -i '' 's/{{TOOL_NAME}}/GitHub CLI/g'
find . -type f -name "*.bash" -o -name "*.md" -o -name "*.yml" | xargs sed -i '' 's/{{TOOL_DESCRIPTION}}/Command-line tool for GitHub operations and workflows/g'
find . -type f -name "*.bash" -o -name "*.md" -o -name "*.yml" | xargs sed -i '' 's/{{TOOL_GITHUB_REPO}}/https:\/\/github.com\/cli\/cli/g'
find . -type f -name "*.bash" -o -name "*.md" -o -name "*.yml" | xargs sed -i '' 's/{{TOOL_HOMEPAGE}}/https:\/\/cli.github.com\//g'
```

### 4. Update Repository Configuration

```bash
# Update remote origin
git remote set-url origin https://github.com/rsvalerio/asdf-gh.git

# Update package.json (if present)
sed -i '' 's/"name": "asdf-plugin-template"/"name": "asdf-gh"/g' package.json

# Update README.md title
sed -i '' 's/# asdf-plugin-template/# asdf-gh/g' README.md
```

## Architecture Support

- **Primary Target**: macOS (ARM64 and AMD64) and Linux (AMD64)
- **Future Consideration**: Windows support can be added later

## Required Scripts Implementation

### 1. `bin/list-all` (Required)

**Purpose**: List all available GitHub CLI versions

**Implementation Strategy**:
- Parse the GitHub CLI releases from their GitHub API
- Extract version numbers from release tags (e.g., `v2.40.1` → `2.40.1`)
- Return space-separated list of versions, newest last

**Example Output**:
```
2.38.0 2.39.0 2.40.0 2.40.1
```

**Implementation Details**:
```bash
#!/usr/bin/env bash

# Fetch releases from GitHub API
releases_url="https://api.github.com/repos/cli/cli/releases"
versions=$(curl -s "$releases_url" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "v//g' | sed 's/"//g' | sort -V)

echo "$versions"
```

### 2. `bin/download` (Required)

**Purpose**: Download the appropriate binary for the specified version

**Implementation Strategy**:
- Determine the system architecture and OS
- Construct the download URL based on version, OS, and architecture
- Download the appropriate archive (tar.gz for Linux, zip for macOS)
- Extract the binary from the archive

**Download URL Pattern**:
- macOS ARM64: `https://github.com/cli/cli/releases/download/v{VERSION}/gh_{VERSION}_macOS_arm64.tar.gz`
- macOS AMD64: `https://github.com/cli/cli/releases/download/v{VERSION}/gh_{VERSION}_macOS_amd64.tar.gz`
- Linux AMD64: `https://github.com/cli/cli/releases/download/v{VERSION}/gh_{VERSION}_linux_amd64.tar.gz`

**Implementation Details**:
```bash
#!/usr/bin/env bash

set -euo pipefail

version="$ASDF_INSTALL_VERSION"
download_path="$ASDF_DOWNLOAD_PATH"

# Detect OS and architecture
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)

case "$os" in
    darwin)
        case "$arch" in
            arm64) arch_suffix="arm64" ;;
            x86_64) arch_suffix="amd64" ;;
            *) echo "Unsupported macOS architecture: $arch" >&2; exit 1 ;;
        esac
        os_suffix="macOS"
        archive_ext="tar.gz"
        ;;
    linux)
        case "$arch" in
            x86_64) arch_suffix="amd64" ;;
            *) echo "Unsupported Linux architecture: $arch" >&2; exit 1 ;;
        esac
        os_suffix="linux"
        archive_ext="tar.gz"
        ;;
    *)
        echo "Unsupported operating system: $os" >&2
        exit 1
        ;;
esac

# Construct download URL
download_url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_${os_suffix}_${arch_suffix}.${archive_ext}"
archive_file="${download_path}/gh.${archive_ext}"

# Download the binary
echo "Downloading GitHub CLI v${version} for ${os_suffix} ${arch_suffix}..."
curl -L -o "$archive_file" "$download_url"

# Extract the binary
if [ "$archive_ext" = "tar.gz" ]; then
    tar -xzf "$archive_file" -C "$download_path"
else
    unzip -q "$archive_file" -d "$download_path"
fi

rm "$archive_file"

echo "Downloaded GitHub CLI v${version} successfully"
```

### 3. `bin/install` (Required)

**Purpose**: Install the downloaded binary to the installation directory

**Implementation Strategy**:
- Copy the extracted `gh` binary to `ASDF_INSTALL_PATH/bin/`
- Make the binary executable
- Verify installation by running `gh --version`

**Implementation Details**:
```bash
#!/usr/bin/env bash

set -euo pipefail

install_path="$ASDF_INSTALL_PATH"
download_path="$ASDF_DOWNLOAD_PATH"

# Create bin directory
mkdir -p "${install_path}/bin"

# Copy binary to installation directory
cp "${download_path}/gh_*/bin/gh" "${install_path}/bin/gh"

# Make executable
chmod +x "${install_path}/bin/gh"

# Verify installation
if "${install_path}/bin/gh" --version >/dev/null 2>&1; then
    echo "GitHub CLI installed successfully"
else
    echo "Installation verification failed" >&2
    exit 1
fi
```

## Optional Scripts Implementation

### 4. `bin/latest-stable` (Recommended)

**Purpose**: Determine the latest stable version

**Implementation Strategy**:
- Query GitHub API for the latest release
- Filter out pre-releases and release candidates
- Return the latest stable version number

**Implementation Details**:
```bash
#!/usr/bin/env bash

# Get latest stable release from GitHub API
latest_url="https://api.github.com/repos/cli/cli/releases/latest"
latest_version=$(curl -s "$latest_url" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "v//g' | sed 's/"//g')

echo "$latest_version"
```

### 5. `bin/help.overview`

**Purpose**: Provide plugin and tool description

**Implementation Details**:
```bash
#!/usr/bin/env bash

cat << 'EOF'
GitHub CLI (gh) is a command-line tool for GitHub operations and workflows.
This plugin manages the installation and versioning of the GitHub CLI binary.

The GitHub CLI allows you to:
- Work with GitHub issues, pull requests, and releases
- Manage repositories and organizations
- Authenticate with GitHub using GitHub CLI
- Run GitHub Actions workflows
- Create and manage gists
- Clone repositories with authentication
- Integrate with your development workflow

This plugin supports macOS (ARM64 and AMD64) and Linux (AMD64) architectures.
EOF
```

### 6. `bin/help.deps`

**Purpose**: List system dependencies

**Implementation Details**:
```bash
#!/usr/bin/env bash

cat << 'EOF'
curl
tar
EOF
```

### 7. `bin/help.config`

**Purpose**: Configuration information

**Implementation Details**:
```bash
#!/usr/bin/env bash

cat << 'EOF'
No special configuration is required for the GitHub CLI plugin.

After installation, you'll need to:
1. Authenticate with GitHub: gh auth login
2. Choose your preferred protocol (HTTPS or SSH)
3. Use gh commands to interact with GitHub

For more information, visit: https://cli.github.com/manual/
EOF
```

### 8. `bin/help.links`

**Purpose**: Relevant links

**Implementation Details**:
```bash
#!/usr/bin/env bash

cat << 'EOF'
Documentation: https://cli.github.com/manual/
GitHub Repository: https://github.com/cli/cli
Installation Guide: https://cli.github.com/manual/installation
EOF
```

## Plugin Structure

After template setup, the plugin structure will be:

```
asdf-gh/
├── bin/
│   ├── list-all
│   ├── download
│   ├── install
│   ├── latest-stable
│   ├── help.overview
│   ├── help.deps
│   ├── help.config
│   └── help.links
├── lib/
│   └── utils.bash
├── README.md
├── LICENSE
├── .github/
│   └── workflows/
│       └── test.yml
└── package.json
```

## Testing Strategy

### GitHub Actions Workflow

```yaml
name: Test
on:
  push:
    branches:
      - main
  pull_request:

jobs:
  plugin_test:
    name: asdf plugin test
    strategy:
      matrix:
        os:
          - ubuntu-latest
          - macos-latest
    runs-on: ${{ matrix.os }}
    steps:
      - name: asdf_plugin_test
        uses: asdf-vm/actions/plugin-test@v2
        with:
          command: "gh --version"
```

### Manual Testing Commands

```bash
# Test plugin installation
asdf plugin add gh https://github.com/rsvalerio/asdf-gh

# Test version listing
asdf list all gh

# Test installation
asdf install gh latest
asdf install gh 2.40.1

# Test functionality
asdf global gh 2.40.1
gh --version
```

## Error Handling

### Download Failures
- Check network connectivity
- Verify URL construction
- Handle HTTP error codes
- Provide meaningful error messages

### Installation Failures
- Verify binary extraction
- Check file permissions
- Validate binary integrity
- Clean up on failure

### Architecture Detection
- Support ARM64 and AMD64 for macOS
- Support AMD64 for Linux
- Provide clear error for unsupported architectures
- Future-proof for additional architectures

## Security Considerations

### Binary Verification
- Consider implementing checksum verification
- Document security implications
- Provide guidance on verifying binary authenticity

### Download Security
- Use HTTPS for all downloads
- Validate download URLs
- Handle redirects securely

## Future Enhancements

### Windows Support
- Add Windows binary support
- Detect Windows architectures
- Handle different package formats

### Version Management
- Implement version comparison
- Support version ranges
- Add version aliases

### Performance Optimizations
- Cache version lists
- Implement parallel downloads
- Add progress indicators

## Implementation Timeline

1. **Phase 1**: Initial Setup
   - Clone and customize asdf plugin template
   - Update all template placeholders with `gh`-specific values
   - Set up repository and basic structure

2. **Phase 2**: Core functionality
   - Implement required scripts (`list-all`, `download`, `install`)
   - Basic macOS and Linux support
   - Initial testing

3. **Phase 3**: Enhanced features
   - Add optional scripts (`latest-stable`, help scripts)
   - Improve error handling
   - Add comprehensive testing

4. **Phase 4**: Polish and optimization
   - Performance improvements
   - Documentation completion
   - Community feedback integration

## Reference Implementation

This plugin is inspired by the existing `asdf-github-cli` plugin by bartlomiejdanek:
- Repository: https://github.com/bartlomiejdanek/asdf-github-cli
- Provides a reference implementation for GitHub CLI plugin structure
- Can be used as a starting point for understanding GitHub CLI binary distribution

## Conclusion

This design document provides a comprehensive plan for implementing an asdf plugin for GitHub CLI. The plugin will follow asdf best practices, support the required functionality, and provide a solid foundation for future enhancements.

The implementation focuses on simplicity, reliability, and maintainability while providing all the essential features needed for effective version management of the GitHub CLI tool. The plugin will support both macOS and Linux platforms, making it accessible to a wide range of developers.
