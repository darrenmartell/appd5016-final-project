#!/bin/bash
set -e

echo "========================================="
echo "Starting Series Catalog (Single Container)"
echo "========================================="

# Create log directories
mkdir -p /var/log/supervisor

echo "Starting supervisor to manage services..."
echo "  • API (port 5130)"
echo "  • Frontend (port 5131)"
echo "  • Nginx reverse proxy (port 8080)"
echo ""

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
