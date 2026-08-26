-- Preview Mermaid diagrams (fenced ```mermaid blocks) inline in Neovim via
-- Kitty's graphics protocol. Requires:
--   - Neovim running directly in a Kitty window (NOT inside a nested :terminal
--     buffer -- libvterm doesn't support the graphics protocol, see
--     https://github.com/neovim/neovim/issues/32189)
--   - `mermaid-cli` (mmdc) on PATH, e.g. `pnpm add -g @mermaid-js/mermaid-cli`
--   - ImageMagick (`magick`/`convert`), used by image.nvim's magick_cli processor
--
-- No `:command` is exposed by mermaid-preview.nvim yet (it's early-stage --
-- see the plugin's own README TODOs), so this wires up <leader>mp to call its
-- preview() function directly: put the cursor inside a ```mermaid block and
-- press it.

---@type LazySpec
return {
  {
    -- NOTE: AstroNvim v6 tracks nvim-treesitter's `main` branch, whose `setup()`
    -- only reads `install_dir` -- parsers must be requested through AstroCore.
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      treesitter = { ensure_installed = { "markdown", "markdown_inline" } },
    },
  },
  {
    "3rd/image.nvim",
    build = false,
    opts = {
      processor = "magick_cli",
    },
  },
  {
    "zacharyeller13/mermaid-preview.nvim",
    dependencies = { "3rd/image.nvim" },
    ft = "markdown",
    opts = {},
    keys = {
      {
        "<leader>mp",
        function() require("mermaid-preview").preview() end,
        desc = "Preview Mermaid diagram under cursor",
      },
    },
  },
}
