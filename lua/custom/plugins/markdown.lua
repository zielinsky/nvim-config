return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'quarto' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {},
    config = function(_, opts)
      local render = require 'render-markdown'
      render.setup(opts)

      local function set_markdown_mappings(bufnr)
        vim.keymap.set('n', '<leader>mr', function()
          vim.cmd 'RenderMarkdown toggle'
        end, {
          buffer = bufnr,
          desc = 'Toggle rendered Markdown view',
        })
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'markdown', 'quarto' },
        callback = function(event)
          set_markdown_mappings(event.buf)
        end,
      })

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local filetype = vim.bo[bufnr].filetype
        if filetype == 'markdown' or filetype == 'quarto' then
          set_markdown_mappings(bufnr)
        end
      end
    end,
  },
}
