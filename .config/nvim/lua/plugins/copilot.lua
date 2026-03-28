return {
  {
    "zbirenbaum/copilot.lua",
    -- Lazy load when entering Insert mode (or change based on preference)
    event = "InsertEnter",
    -- You can also allow command-based loading
    cmd = "Copilot",
    -- If copilot needs build steps, you can include `build`, but here none is necessary

    -- `opts` is used by AstroNvim’s plugin override pattern (merged with defaults)
    opts = {
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
        layout = {
          position = "right",
          ratio = 0.4,
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<C-l>",
          next = "<C-n>",
          prev = "<C-p>",
          dismiss = "<C-]>",
        },
      },
      -- optional: disable in certain filetypes if you want
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ["."] = false,
      },
      -- node command if needed
      copilot_node_command = "node",
      server_opts_overrides = {},
    },
    -- A `config` function is run after opts are merged; here we set up plugin
    config = function(plugin, opts) require("copilot").setup(opts) end,
  },
  {
    "zbirenbaum/copilot-cmp",
    event = "InsertEnter",
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function(_, opts) require("copilot_cmp").setup(opts) end,
    opts = {}, -- copilot-cmp default opts
  },
}
