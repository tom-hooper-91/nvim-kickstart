vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  file_types = { 'markdown', 'octo' },
}

vim.keymap.set('n', '<leader>tm', function() require('render-markdown').toggle() end, { desc = '[T]oggle rendered [M]arkdown' })
