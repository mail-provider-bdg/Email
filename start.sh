#!/bin/bash

# start.sh - Main entry point for setting up the complete email system
# This script automatically initiates all necessary components
# Usage: ./start.sh

# Set strict error handling
set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${PURPLE}============================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}============================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    echo "Please run: sudo ./start.sh"
    exit 1
fi

# Welcome message
print_header "BDG Software Email System Setup"
echo "This script will automatically set up your complete email system with:"
echo "• Mail server (Postfix + Dovecot or Docker Mail Server)"
echo "• Roundcube webmail with custom theme"
echo "• User registration system"
echo "• Email forwarding to admin"
echo "• Security components"
echo ""
echo "Domain: bdgsoftware.cloud"
echo ""

# Make all scripts executable
print_step "Making all scripts executable..."
find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \;
print_success "All scripts are now executable"

# Check for dependencies
print_step "Checking for required dependencies..."
if ! command -v apt-get &> /dev/null; then
    print_error "This script requires apt-get. Please run on Ubuntu/Debian."
    exit 1
fi

# Start the main setup script
print_header "Starting Complete Mail System Setup"
print_step "Launching setup-complete-mail-system.sh..."

# Execute the non-interactive setup script
if [ -f "$SCRIPT_DIR/setup-noninteractive.sh" ]; then
    "$SCRIPT_DIR/setup-noninteractive.sh"
else
    print_warning "Non-interactive setup script not found, falling back to interactive setup"
    "$SCRIPT_DIR/setup-complete-mail-system.sh"
fi

# Final message
print_header "Setup Complete!"
print_success "Your email system has been successfully set up!"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Configure DNS records for bdgsoftware.cloud"
echo "2. Test email sending/receiving"
echo "3. Access webmail and create accounts"
echo ""
echo -e "${YELLOW}⚠️  Important:${NC}"
echo "• Change default passwords immediately"
echo "• Set up SSL certificates for production use"
echo "• Configure firewall rules for your specific network"
echo ""
echo -e "${GREEN}Thank you for using BDG Software Email System!${NC}"