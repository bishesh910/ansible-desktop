#!/usr/bin/env bash
# One command to set up a fresh Debian or Ubuntu GNOME desktop like mine.
# Run from a terminal inside your GNOME session:   ./bootstrap.sh
# Extra arguments are passed to ansible-playbook, e.g.  ./bootstrap.sh --tags user
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo ">> Installing Ansible"
  sudo apt-get update
  sudo apt-get install -y ansible git
fi

if ! ansible-galaxy collection list 2>/dev/null | grep -q '^community\.general'; then
  echo ">> Installing the community.general collection"
  ansible-galaxy collection install -r requirements.yml
fi

echo ">> Applying the playbook (your sudo password is asked once)"
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass "$@"

cat <<'MSG'

Done. If GNOME Shell extensions were installed just now, log out and back in so they load,
then run ./bootstrap.sh once more so their settings apply.
MSG
