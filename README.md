## Joshua's Dotfiles

>  As per usual with dotfile repos, this should be used more for inspiration rather than ran as-is (unless you are me).

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

## Primary Commands

Run `. ./manage.sh && push` to copy files _out_ of this repo.

Run `. ./manage.sh && pull` to pull local settings _into_ this repo.

> If either of the above commands fail and your terminal exits, use ` || true` for easier debugging

## Notes to Self

- [My dotfiles cheatsheet](https://docs.joshuatz.com/cheatsheets/dotfiles/)
- [My Bash / Shell Scripting Cheatsheet](https://docs.joshuatz.com/cheatsheets/bash-and-shell/)
- On Linux, ZSH completions should be under `/usr/share/zsh/functions/Completion/Unix/`. On macOS, they are under `/usr/share/zsh/${version}/functions`
	- To explore with VS Code: `code "/usr/share/zsh/$ZSH_VERSION/functions"`
