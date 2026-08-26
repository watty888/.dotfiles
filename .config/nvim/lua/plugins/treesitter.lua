if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Treesitter
--
-- NOTE: AstroNvim v6 tracks nvim-treesitter's `main` branch, whose `setup()` only
-- reads `install_dir` -- an `ensure_installed` passed to the plugin directly is
-- silently ignored. Request parsers through AstroCore instead.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      ensure_installed = {
        "lua",
        "vim",
        -- add more arguments for adding more treesitter parsers
      },
    },
  },
}
