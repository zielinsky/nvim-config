return {
  {
    'scalameta/nvim-metals',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ft = { 'scala', 'sbt', 'java' },
    config = function()
      local metals = require 'metals'
      local metals_config = metals.bare_config()

      local ok, blink = pcall(require, 'blink.cmp')
      if ok then
        metals_config.capabilities = blink.get_lsp_capabilities()
      end

      metals_config.init_options.statusBarProvider = 'on'

      metals_config.on_attach = function(client, bufnr)
        local dap_ok = pcall(require, 'dap')
        if dap_ok then
          metals.setup_dap()
        end
      end

      local group = vim.api.nvim_create_augroup('nvim-metals', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'scala', 'sbt', 'java' },
        callback = function()
          metals.initialize_or_attach(metals_config)
        end,
        group = group,
      })
    end,
  },
}
