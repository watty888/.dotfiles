return {
  "mfussenegger/nvim-dap",
  config = function()
    local dap = require "dap"

    -- Define the adapter
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "js-debug-adapter",
        args = { "${port}" },
      },
    }

    -- Define the configuration for TypeScript/JavaScript
    for _, language in ipairs { "typescript", "javascript", "typescriptreact", "javascriptreact" } do
      dap.configurations[language] = {
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to Next.js Server",
          port = 9230, -- Default Node.js debug port
          restart = true,
          sourceMaps = true,
          localRoor = vim.fn.getcwd(),
          remoteRoot = vim.fn.getcwd(),
          skipFiles = { "<node_internals>/**", "node_modules/**" },
          protocol = "inspector",
          console = "integratedTerminal",
        },
      }
    end
  end,
}
