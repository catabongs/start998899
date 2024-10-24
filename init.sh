#!/bin/bash

# Script to initialize a Linux system with dotfiles and required packages
# Usage: ./init.sh

set -euo pipefail  # Exit on error, undefined var, and pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_FILES_DIR="${SCRIPT_DIR}/dot_files"
PKGS_FILE="${SCRIPT_DIR}/pkgs"

# Print with color
print_msg() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1" >&2
}

# Detect package manager
detect_pkg_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        print_error "No supported package manager found"
        exit 1
    fi
}

install_packages() {
    local pkg_manager="$1"
    local packages
    
    # Read packages from pkgs file, ignoring comments and empty lines
    if [[ ! -f "$PKGS_FILE" ]]; then
        print_error "Package list file not found: $PKGS_FILE"
        exit 1
    fi  # Added missing 'fi'
    
    # Get packages, excluding comments and empty lines
    packages=$(grep -v '^#' "$PKGS_FILE" | grep -v '^[[:space:]]*$')
    print_msg "Installing packages using $pkg_manager..."
    
    case "$pkg_manager" in
        apt)
            sudo apt update
            while read -r pkg; do
                print_msg "Installing $pkg..."
                sudo apt install -y "$pkg"
            done <<< "$packages"
            ;;
        dnf)
            sudo dnf update -y
            while read -r pkg; do
                print_msg "Installing $pkg..."
                sudo dnf install -y "$pkg"
            done <<< "$packages"
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            while read -r pkg; do
                print_msg "Installing $pkg..."
                sudo pacman -S --noconfirm "$pkg"
            done <<< "$packages"
            ;;
        zypper)
            sudo zypper refresh
            while read -r pkg; do
                print_msg "Installing $pkg..."
                sudo zypper install -y "$pkg"
            done <<< "$packages"
            ;;
    esac
}

# Install dotfiles
install_dotfiles() {
    print_msg "Installing dotfiles..."
    
    if [[ ! -d "$DOT_FILES_DIR" ]]; then
        print_error "Dotfiles directory not found: $DOT_FILES_DIR"
        exit 1
    fi  # Fixed closing brace to 'fi'
    
    # Create backups of existing dotfiles
    local backup_dir="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # List of dotfiles to install
    local files=("bashrc" "bash_prompt" "bash_aliases" "inputrc" "tmux.conf")
    
    for file in "${files[@]}"; do
        # Source and destination paths
        local src="${DOT_FILES_DIR}/${file}"
        local dest="${HOME}/.${file}"
        
        # Backup existing file if it exists
        if [[ -f "$dest" ]]; then
            print_msg "Backing up existing ${dest} to ${backup_dir}"
            mv "$dest" "${backup_dir}/${file}"
        fi
        
        # Copy new dotfile
        if [[ -f "$src" ]]; then
            print_msg "Installing .${file}"
            cp "$src" "$dest"
        else
            print_error "Source file not found: $src"
        fi
    done
}

# Main execution
main() {
    print_msg "Starting system initialization..."
    
    # Detect and install packages
    local pkg_manager
    pkg_manager=$(detect_pkg_manager)
    install_packages "$pkg_manager"
    
    # Install dotfiles
    install_dotfiles
    
    print_msg "System initialization complete!"
    print_msg "Please restart your shell or source the new dotfiles"
}

main