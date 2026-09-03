vim.pack.add { 'https://github.com/sphamba/smear-cursor.nvim' }

require('smear_cursor').setup {
  smear_between_buffers = true,
  smear_between_neighbor_lines = true,
  scroll_buffer_space = true,
  legacy_computing_symbols_support = false,
  smear_insert_mode = true,
}

vim.keymap.set('n', '<leader>tc', '<cmd>SmearCursorToggle<cr>', { desc = '[T]oggle smear [C]ursor' })
