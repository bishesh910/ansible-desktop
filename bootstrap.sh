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

# Ubuntu 25.10+ selects sudo-rs as the default sudo. It does not reproduce the custom
# prompt Ansible passes with -p, so --ask-become-pass hangs and the run dies with
# "Timed out waiting for become success or become password prompt". Classic sudo stays
# installed next to it as /usr/bin/sudo.ws, so point Ansible at that instead.
become_args=()
if sudo --version 2>/dev/null | grep -qi '^sudo-rs'; then
  if [ -x /usr/bin/sudo.ws ]; then
    echo ">> sudo is sudo-rs, which Ansible cannot prompt through; using /usr/bin/sudo.ws"
    become_args=(-e ansible_become_exe=/usr/bin/sudo.ws)
  else
    echo ">> sudo is sudo-rs and classic sudo is missing; installing it"
    sudo apt-get install -y sudo
    become_args=(-e ansible_become_exe=/usr/bin/sudo.ws)
  fi
fi

echo ">> Applying the playbook (your sudo password is asked once)"
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass "${become_args[@]}" "$@"

cat <<'MSG'

Done. If GNOME Shell extensions were installed just now, log out and back in so they load,
then run ./bootstrap.sh once more so their settings apply.
MSG
