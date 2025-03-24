#!/usr/bin/env bash

export JT_LOGO=$(ghead -n -1 < "$DOTFILES_DIR/ascii_art/jt.utf8.ans")

export GIT_LOGO=$(cat <<- EOF
	   .oooooo.     ooooo  ooooooooooooo
	  d8P'   Y8b     888   8    888    8
	  888            888        888
	  888            888        888
	  888     ooooo  888        888
	  .88.    .88'   888        888
	  .Y8bood8P.    o888o      o888o
EOF
)
