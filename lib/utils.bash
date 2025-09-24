#!/usr/bin/env bash

set -euo pipefail

export GH_REPO="https://github.com/cli/cli"
export TOOL_NAME="gh"
export TOOL_TEST="gh --version"

# Print error message and exit with status 1
fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

# Fetch and parse GitHub CLI release tags from GitHub API
list_github_tags() {
	releases_url="https://api.github.com/repos/cli/cli/releases"
	curl "${curl_opts[@]}" "$releases_url" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "v//g' | sed 's/"//g'
}

# Sort versions in descending order (newest first)
sort_versions() {
	sort -V -r
}

# List all available GitHub CLI versions
list_all_versions() {
	list_github_tags
}

# Download GitHub CLI release archive for specified version and platform
download_release() {
	local version filename url
	version="$1"
	filename="$2"

	# Resolve "latest" to actual version number
	if [[ "$version" == "latest" ]]; then
		latest_url="https://api.github.com/repos/cli/cli/releases/latest"
		version=$(curl "${curl_opts[@]}" "$latest_url" | grep -o '"tag_name": "v[^"]*"' | sed 's/"tag_name": "v//g' | sed 's/"//g')
	fi

	os=$(uname -s | tr '[:upper:]' '[:lower:]')
	arch=$(uname -m)

	case "$os" in
	darwin)
		case "$arch" in
		arm64) arch_suffix="arm64" ;;
		x86_64) arch_suffix="amd64" ;;
		*) fail "Unsupported macOS architecture: $arch" ;;
		esac
		os_suffix="macOS"
		archive_ext="zip"
		;;
	linux)
		case "$arch" in
		x86_64) arch_suffix="amd64" ;;
		*) fail "Unsupported Linux architecture: $arch" ;;
		esac
		os_suffix="linux"
		archive_ext="tar.gz"
		;;
	*)
		fail "Unsupported operating system: $os"
		;;
	esac

	url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_${os_suffix}_${arch_suffix}.${archive_ext}"

	echo "* Downloading GitHub CLI v${version} for ${os_suffix} ${arch_suffix}..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

# Install GitHub CLI binary to specified path and verify installation
install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"

		# Find the extracted directory
		extracted_dir=$(find "${ASDF_DOWNLOAD_PATH}" -maxdepth 1 -name "gh_*" -type d | head -1)
		if [[ -z "$extracted_dir" ]]; then
			fail "Could not find extracted gh directory"
		fi

		cp "${extracted_dir}/bin/gh" "${install_path}/gh"

		chmod +x "${install_path}/gh"

		if "${install_path}/gh" --version >/dev/null 2>&1; then
			echo "GitHub CLI $version installation was successful!"
		else
			fail "Installation verification failed"
		fi
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
