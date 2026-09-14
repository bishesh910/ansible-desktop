# My desktop, as code

Ansible playbook that turns a fresh **Debian 12/13** or **Ubuntu 22.04+** GNOME install into my
customised desktop: Mac-style keyboard, theme, dock, terminal, shell, and the apps I use.
Captured from my Debian 13 / GNOME 48 machine; every part is idempotent, so re-running it only
changes what drifted.

## Quick start

```bash
sudo apt install -y git
git clone https://github.com/bishesh910/ansible-desktop.git ~/ansible-desktop
cd ~/ansible-desktop
./bootstrap.sh
```

`bootstrap.sh` installs Ansible if needed, asks for your sudo password once, and applies everything.
Run it **from a terminal inside the GNOME session** of the user being set up (dconf, `flatpak --user`
and `gnome-extensions` need the session D-Bus). After the first run, **log out and back in** so the
new GNOME extensions load, then run it once more so their settings apply.

## What it sets up

| Area | What |
|---|---|
| keyd | Mac-style modifiers on a PC keyboard: Alt key = Cmd (acts as Ctrl, Cmd+Q = close window, Cmd+Space = Search Light, Cmd+Tab = app switcher…), Windows key = Option (hold-Shift + Mac symbols + word navigation), Ctrl+Cmd+Q = lock screen. `files/keyd/default.conf`. Built from source where the distro has no package |
| GNOME | `us+mac` keyboard layout, dark mode, purple accent, Tela-purple-dark icons, WhiteSur-Dark shell theme, window buttons (close/min/max), touchpad speed, idle/lock delays, Ctrl+Shift+S screenshot, Ctrl+Shift+B opens Chrome |
| Extensions | Dash to Dock (bottom, always visible, dots, no Apps button), Search Light (Super+Space), Clipboard Indicator, Caffeine, User Themes, AppIndicator. The right build for the running GNOME version is fetched from extensions.gnome.org |
| Tilix (default) + GNOME Terminal | Mac-style shortcuts (Cmd+T/N/F/G/comma, Ctrl+Tab / Ctrl+Shift+Tab for tabs, Cmd+1-9, Cmd+C/V, Cmd+Shift+W close tab, Cmd+Shift+R rename tab), dark, JetBrainsMono Nerd Font 11, Tokyo Night. Tilix keeps a renamed tab's name even when a remote SSH prompt sends its own title |
| Shell | readline word-delete on Option+Backspace/Delete, Starship prompt + config, `title NAME` to name a tab, `subl` helper, `~/.local/bin` on PATH |
| Apps | VS Code (Microsoft repo), Google Chrome, Sublime Text, Bitwarden (Flathub, user install), Telegram Desktop (official tarball in `~/.local/opt/Telegram`, self-updating), claude-desktop, tmux, htop, remmina |
| Remote access | Tailscale (`tailscaled` running), Teleport `tsh` client, NetBird service + tray UI, each from its vendor apt repo with the signing key shipped in `files/apt-keyrings/`. Log in to each once afterwards (`sudo tailscale up`, `tsh login`, the NetBird tray) |
| Autostart | NetBird tray, Remmina applet, Bitwarden |
| Dock | favourites: Files, Firefox, Chrome, Tilix, claude-desktop, Telegram |

Not included on purpose: the JumpCloud agent (enrolment-specific) and the Dash2Dock Animated extension,
which crashed GNOME Shell whenever an app quit.

Two favourites are Debian-specific: `firefox-esr.desktop` (Ubuntu's Firefox is a snap with a different id) and the
Telegram launcher id, which Telegram derives from its install path (`~/.local/opt/Telegram`), so it matches only
when the user name is the same. Fix the list in `files/dconf/shell.ini` if the dock shows a gap.

## Debian vs Ubuntu

The same playbook runs on both. Differences it handles by itself:

- Packages a release does not ship are skipped with a note (for example `xdg-terminal-exec` on older Ubuntu).
- `keyd` is installed from apt where packaged (Debian 13, Ubuntu 24.04+) and built from source otherwise (Ubuntu 22.04).
- GNOME Shell extensions are downloaded for the detected Shell version (48, 46, 42…).
- The default terminal is set both the new way (`~/.config/xdg-terminals.list`) and the old way
  (`x-terminal-emulator` alternative + `org.gnome.desktop.default-applications.terminal`), so Ctrl+Alt+T and
  "Open in Terminal" pick Tilix on either.
- On Ubuntu, the stock dock is replaced by Dash to Dock (same settings), while Ubuntu's desktop icons and tiling
  assistant stay enabled.

## Layout

```
bootstrap.sh          install Ansible + run the playbook
playbook.yml          two plays: system (sudo) and user; tags `system` / `user`
group_vars/all.yml    everything tunable: package lists, versions, toggles, dconf map
files/keyd/           keyd config
files/dconf/*.ini     dconf dumps, loaded per path (edit these to change settings)
files/home/           dotfiles copied verbatim
```

## Everyday use

```bash
./bootstrap.sh                          # apply everything
./bootstrap.sh --tags user              # only the $HOME half, no sudo needed
./bootstrap.sh --check --diff           # dry run: show what would change
```

To capture settings after tweaking something in a GUI, re-dump that path and commit:

```bash
dconf dump /com/gexperts/Tilix/ > files/dconf/tilix.ini      # one line per path in group_vars
```

`~/.bashrc` additions live between `# BEGIN/END ANSIBLE MANAGED` markers; edit them in `playbook.yml`, not in the file.
