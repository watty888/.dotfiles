-- Persistence for the colorscheme picked through `<Leader>ft`.
-- The Snacks picker only applies a theme to the running session, so the choice is recorded
-- here and read back by `lua/plugins/astroui.lua` on the next start.

local M = {}

local default = "catppuccin-mocha"
local statefile = vim.fs.joinpath(vim.fn.stdpath "state" --[[@as string]], "colorscheme")

--- The persisted colorscheme, or the default when nothing has been picked yet.
---@return string
function M.load()
  if vim.fn.filereadable(statefile) == 0 then return default end
  local name = vim.trim(vim.fn.readfile(statefile)[1] or "")
  return name ~= "" and name or default
end

--- Record a colorscheme as the one to load on the next start.
---@param name string
function M.save(name)
  vim.fn.mkdir(vim.fs.dirname(statefile), "p")
  vim.fn.writefile({ name }, statefile)
end

return M
