# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Neovim configuration built on **AstroNvim v6** using **Lazy.nvim** as the plugin manager. It targets TypeScript/JavaScript development with Claude Code integration, DAP debugging, and Markdown/Mermaid authoring.

## Code Style

Lua formatting is handled by **StyLua**:

- 120 character line width
- 2-space indentation
- Unix line endings
- Double quotes preferred

Run the linter/formatter manually:

```bash
stylua lua/
selene lua/
```

## Architecture

### Plugin Loading Order

1. `init.lua` — bootstraps Lazy.nvim, then loads `lazy_setup` and `polish`
2. `lua/lazy_setup.lua` — configures Lazy.nvim with AstroNvim base + community + user plugins
3. `lua/community.lua` — AstroCommunity module imports (language packs, UI modules)
4. `lua/plugins/` — individual user plugin overrides and additions

### Plugin Configuration Pattern

Each file in `lua/plugins/` returns a table (or list of tables) conforming to the Lazy.nvim spec. To override an AstroNvim default, return a table with the same plugin name and use `opts` to merge changes:

```lua
return {
  "plugin/name",
  opts = {
    -- your overrides
  },
}
```

### Key Files

| File                          | Purpose                                                                                                     |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `lua/plugins/astrocore.lua`   | Vim options, key mappings, autocmds, feature toggles                                                        |
| `lua/plugins/astroui.lua`     | Colorscheme (catppuccin-mocha, transparent bg), icons, highlights                                                          |
| `lua/plugins/claudecode.lua`  | claudecode.nvim — Claude Code integration (`<leader>ac` / `<leader>af` / `<leader>am`)                       |
| `lua/plugins/dap.lua`         | DAP for Node.js/Next.js (pwa-node attach, port 9230, source maps)                                           |
| `lua/plugins/mermaid.lua`     | Inline Mermaid preview via Kitty graphics protocol (`<leader>mp`)                                            |
| `lua/plugins/user.lua`        | Custom Snacks.nvim dashboard header                                                                         |
| `lua/community.lua`           | AstroCommunity imports: lua, typescript, astro, markdown, prettier, eslint, catppuccin, trouble-nvim, mini-animate, markdown-preview |

### External Dependencies

Some plugins need tooling on `PATH` and stay inert without it:

- `dap.lua` — `js-debug-adapter` (installable via Mason)
- `mermaid.lua` — `mmdc` (`@mermaid-js/mermaid-cli`) and ImageMagick (`magick`), plus Neovim running directly in Kitty (not a nested `:terminal` buffer)

### Disabled Template Files

These files contain `if true then return end` guards and are intentionally inactive — remove the guard to activate:

- `lua/polish.lua` — post-setup customizations
- `lua/plugins/astrolsp.lua` — LSP overrides
- `lua/plugins/mason.lua` — Mason tool overrides
- `lua/plugins/none-ls.lua` — none-ls formatter/linter integration
- `lua/plugins/treesitter.lua` — Treesitter parser overrides

## Neovim Configuration Reference

- **AstroNvim docs:** https://docs.astronvim.com
- **AstroCommunity recipes:** browsable at `~/.local/share/nvim/lazy/astrocommunity/`
- **Lock file:** `lazy-lock.json` — commit changes to this when updating plugins
