vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  file_types = { 'markdown', 'octo' },
  html = {
    comment = {
      text = function(ctx)
        if ctx.text:find('AGENT:', 1, true) then return '💬' end
      end,
    },
  },
}

vim.keymap.set('n', '<leader>tm', function() require('render-markdown').toggle() end, { desc = '[T]oggle rendered [M]arkdown' })
