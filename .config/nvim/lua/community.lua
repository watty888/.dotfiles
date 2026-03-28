-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.prettier" },
  { import = "astrocommunity.pack.eslint" },
  { import = "astrocommunity.completion.avante-nvim" },
  { import = "astrocommunity.split-and-window.minimap-vim" },
  { import = "astrocommunity.note-taking.obsidian-nvim" },
  { import = "astrocommunity.colorscheme.catppuccin" },
  { import = "astrocommunity.diagnostics.trouble-nvim" },
  { import = "astrocommunity.scrolling.mini-animate" },
  { import = "astrocommunity.recipes.vscode" },
}
