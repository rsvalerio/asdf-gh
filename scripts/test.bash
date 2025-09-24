#!/usr/bin/env bash

# Test script for asdf-gh plugin
set -euo pipefail

echo "Testing asdf-gh plugin..."

# Check if asdf is available
if ! command -v asdf >/dev/null 2>&1; then
	echo "Error: asdf is not installed"
	exit 1
fi

# Remove existing plugins if present
echo "Removing existing gh plugin..."
asdf plugin remove gh || true

echo "Removing existing asdf-test-gh plugin..."
asdf plugin remove asdf-test-gh || true

# Add plugin from current directory
echo "Adding gh plugin..."
asdf plugin add gh .

# Test the plugin
echo "Testing plugin..."

# First, let's try to install a version manually to see if the plugin works
echo "Installing latest version..."
if asdf install gh latest; then
	echo "Installation successful!"

	# Set the version for testing
	echo "Setting version for testing..."
	asdf set gh latest

	# Now test the installed version
	echo "Testing installed version..."
	if gh --version; then
		echo "Plugin test passed!"
	else
		echo "Plugin test failed - gh command not working!"
		exit 1
	fi
else
	echo "Plugin test failed - installation failed!"
	exit 1
fi

# Cleanup: remove all gh versions
echo "Cleaning up gh versions..."
if asdf list gh 2>/dev/null; then
	asdf list gh | while read -r version; do
		if [[ -n "$version" && "$version" != " " ]]; then
			asdf uninstall gh "$version" || true
		fi
	done
fi

# Remove version setting from .tool-versions
echo "Removing version setting..."
asdf set -u gh || true

# Remove gh line from .tool-versions file if it exists
echo "Cleaning up .tool-versions file..."
if [[ -f .tool-versions ]]; then
	sed -i '' '/^gh /d' .tool-versions || true
fi

# Remove the plugins
echo "Removing gh plugin..."
asdf plugin remove gh || true

echo "Removing asdf-test-gh plugin..."
asdf plugin remove asdf-test-gh || true

echo "Test completed successfully!"
