-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  -- each colorscheme spells transparency differently; keep them all matching the terminal
  {
    "catppuccin/nvim",
    opts = {
      transparent_background = true,
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = { sidebars = "transparent", floats = "transparent" },
    },
  },
  {
    "rebelot/kanagawa.nvim",
    opts = {
      transparent = true,
    },
  },
  {
    "rose-pine",
    opts = {
      styles = { transparency = true },
    },
  },
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      transparent_mode = true,
    },
  },
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      -- change colorscheme (the last theme confirmed in the `<Leader>ft` picker, see `lua/theme.lua`)
      colorscheme = require("theme").load(),
      -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
      highlights = {
        init = { -- this table overrides highlights in all themes
          -- Normal = { bg = "#000000" },
        },
        astrodark = { -- a table of overrides/changes when applying the astrotheme theme
          -- Normal = { bg = "#000000" },
        },
      },
      -- Icons can be configured throughout the interface
      icons = {
        -- configure the loading of the lsp in the status line
        LSPLoading1 = "⠋",
        LSPLoading2 = "⠙",
        LSPLoading3 = "⠹",
        LSPLoading4 = "⠸",
        LSPLoading5 = "⠼",
        LSPLoading6 = "⠴",
        LSPLoading7 = "⠦",
        LSPLoading8 = "⠧",
        LSPLoading9 = "⠇",
        LSPLoading10 = "⠏",
      },
    },
  },
  {
    -- `<Leader>ft` applies a theme for the session only; also persist whatever is confirmed
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          colorschemes = {
            confirm = function(picker, item)
              picker:close()
              if not item then return end
              picker.preview.state.colorscheme = nil -- stop the picker restoring the previous theme
              vim.schedule(function()
                vim.cmd.colorscheme(item.text)
                require("theme").save(item.text)
              end)
            end,
          },
        },
      },
    },
  },
}
