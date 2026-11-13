-- swayimg config. Only overrides live here; the built-in defaults (all keys and
-- options) are listed in /usr/share/swayimg/example.lua, and every option is
-- documented in /usr/share/doc/swayimg/CONFIG.md.
--
-- Colours follow the Catppuccin Latte/Mocha toggle: this file reads the theme
-- word that ~/.config/sway/scripts/theme-switch.sh records, once at startup, so
-- a window that is already open keeps its colours until it is reopened.
-- Colours are ARGB hex: 0xAARRGGBB.

--------------------------------------------------------------------------------
-- Theme
--------------------------------------------------------------------------------
local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local theme = "latte"
local f = io.open(state .. "/desktop-theme", "r")
if f then
  if f:read("*l") == "mocha" then theme = "mocha" end -- "*l": swayimg uses LuaJIT (Lua 5.1)
  f:close()
end

local palettes = {
  mocha = {
    base = 0xff1e1e2e, mantle = 0xff181825, crust = 0xff11111b,
    surface0 = 0xff313244, surface1 = 0xff45475a, overlay0 = 0xff6c7086,
    text = 0xffcdd6f4, panel = 0xcc181825, -- panel: mantle at 80% opacity
  },
  latte = {
    base = 0xffeff1f5, mantle = 0xffe6e9ef, crust = 0xffdce0e8,
    surface0 = 0xffccd0da, surface1 = 0xffbcc0cc, overlay0 = 0xff9ca0b0,
    text = 0xff4c4f69, panel = 0xcce6e9ef,
  },
}
local c = palettes[theme]
local accent = 0xfffbc628 -- the gold focus accent sway uses in both themes

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
-- Opening one file (e.g. from yazi or xdg-open) also loads the other images in
-- its folder, so you can flip through them.
swayimg.imagelist.adjacent = true

swayimg.text.font = "JetBrainsMono Nerd Font" -- same as kitty
swayimg.text.size = 18
swayimg.text.color = c.text
swayimg.text.background = c.panel
swayimg.text.shadow = 0x00000000

--------------------------------------------------------------------------------
-- Viewer
--------------------------------------------------------------------------------
swayimg.viewer.set_window_background(c.base)
swayimg.viewer.set_image_chessboard(16, c.surface0, c.surface1) -- behind transparency
swayimg.viewer.mark_color = accent

-- Left/Right flip between images, like most viewers. (The default uses them
-- to pan; panning still works with the mouse, the scroll wheel, and Up/Down.)
swayimg.viewer.on_key("left", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("right", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("q", function() swayimg.exit() end)

--------------------------------------------------------------------------------
-- Slideshow
--------------------------------------------------------------------------------
swayimg.slideshow.set_window_background(c.base)
swayimg.slideshow.on_key("q", function() swayimg.exit() end)

--------------------------------------------------------------------------------
-- Gallery (thumbnail grid: Enter switches between it and the viewer)
--------------------------------------------------------------------------------
swayimg.gallery.thumb_size = 240
swayimg.gallery.window_color = c.base
swayimg.gallery.unselected_color = c.mantle
swayimg.gallery.selected_color = c.surface0
swayimg.gallery.border_color = accent
swayimg.gallery.border_size = 3
swayimg.gallery.pstore = true -- cache thumbnails on disk so big folders reopen fast
swayimg.gallery.on_key("q", function() swayimg.exit() end)
