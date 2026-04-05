#!/usr/bin/env bash
set -euo pipefail

echo "Updating architecture-audit marketplace..."
claude plugin marketplace update architecture-audit-marketplace

echo "Reinstalling plugin..."
claude plugin uninstall architecture-audit@architecture-audit-marketplace 2>/dev/null || true
claude plugin install architecture-audit@architecture-audit-marketplace

echo ""
echo "Done. Run /reload-plugins in Claude Code to activate."
