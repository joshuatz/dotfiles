local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.automatically_reload_config = true

-- ===== Mouse Handling =====

--- Note: This just applies to WezTerm's own pane handling; not Tmux
config.pane_focus_follows_mouse = true

-- NOTE: This affects _ALL_ `mouse_bindings`; by default Wez won't even
--- consider your bindings unless the bypass key is held down. The default
--- Wez mod key is `SHIFT`.
-- @See https://wezfurlong.org/wezterm/config/lua/config/bypass_mouse_reporting_modifiers.html
config.bypass_mouse_reporting_modifiers = 'SUPER'

config.mouse_bindings = {
	--- Put any desired additions here
}

-- ===== /Mouse Handling =====

-- ===== Keyboard Mappings =====
config.keys = {
	-- Enable CTRL+V
	{ key="v", mods="CTRL", action=wezterm.action{PasteFrom="Clipboard"} },
}
-- ===== /Keyboard Mappings =====

-- ===== Hyperlink Handling =====
--- Default hyperlink rules (note that setting `config.hyperlink_rules` auto-clears
--- the default, so we have to re-assign to override with additions)
config.hyperlink_rules = wezterm.default_hyperlink_rules()

---- VS Code URI handling - https://github.com/microsoft/vscode/issues/4883#issuecomment-270141535
table.insert(config.hyperlink_rules, {
	regex = [[(?m)^(/.+)[\t ]*$]],
	format = 'vscode://file/$1',
})

-- ===== /Hyperlink Handling =====

return config
