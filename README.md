## Joshua's Dotfiles

>  As per usual with dotfile repos, this should be used more for inspiration rather than ran as-is (unless you are me).

## Compatible Shells

Although I try to write cross-shell-compatible code, I tend to prioritize `zsh` over other shells, since that is my daily-driver.

The most frequent places where I might have accidentally hard-coded a zsh-ism into my scripts are with array usage (since zsh uses a different starting index), parameter expansion (zsh has a bunch of unique options), and shell options (like word-splitting and glob expansion), since those by definition differ across shells.

## Dependencies

I try to avoid implicit dependencies with shell scripting when possible, but sometimes it is unavoidable.

As of right now, the most frequently used dependencies would be:

- [fzf](https://github.com/junegunn/fzf)
- Some sort of clipboard manager (which is only an issue on Linux distros where it is not bundled with it):
	- macOS: `pbcopy` / `pbpaste`
	- Linux, X: `xclip`
	- Linux, Wayland: `wl-copy` / `wl-paste`
- [Node.js](https://nodejs.org/en)
- [Python](https://www.python.org/)

These dependencies are optional (there are either fallbacks coded, or only a few utils use them), but are recommended:

- pandoc (for HTML and markdown conversion, etc.)
- `asdf` (for various runtime / package management)

## Primary Commands

Run `./manage.sh push` to copy files _out_ of this repo.

Run `./manage.sh pull` to pull local settings _into_ this repo.

## Credentials / Secrets

Secret values should not be stored anywhere other than a secure password manager.

You can read values out of 1Password in the following ways:

```bash
op read "op://Private/${ITEM_NAME_OR_ID}/${FIELD_NAME}"
# ^ If the item name contains special characters (like `(`)
# then 1Password will autogenerate a unique ID for it instead
# of using the name

# Or, you can query by the item name, regardless if it was
# auto-replaced with a unique ID
op item get ${ITEM_NAME} --vault Private --fields label=${FIELD_NAME}
# ^ Both `--vault` and `--fields` are optional, but wise to
# include for scoping
```

## Notes to Self

- [My dotfiles cheatsheet](https://docs.joshuatz.com/cheatsheets/dotfiles/)
- [My Bash / Shell Scripting Cheatsheet](https://docs.joshuatz.com/cheatsheets/bash-and-shell/)
- On Linux, ZSH completions should be under `/usr/share/zsh/functions/Completion/Unix/`. On macOS, they are under `/usr/share/zsh/${version}/functions`
	- To explore with VS Code: `code "/usr/share/zsh/$ZSH_VERSION/functions"`
