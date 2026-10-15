require('which-key').add { { '<leader>a', group = '[A]gent' } }

vim.keymap.set('n', '<leader>al', '<cmd>TodoTelescope keywords=AGENT<cr>', { desc = '[A]gent: [L]ist notes' })

local agent_note = '<!-- AGENT:  -->'
local agent_note_cursor_col = #'<!-- AGENT: '

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('agent-notes', { clear = true }),
  pattern = 'markdown',
  callback = function(event)
    vim.keymap.set('n', '<leader>an', function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(0, row, row, false, { agent_note })
      vim.api.nvim_win_set_cursor(0, { row + 1, agent_note_cursor_col })
      vim.cmd.startinsert()
    end, { buffer = event.buf, desc = '[A]gent: add [N]ote' })
  end,
})

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  group = vim.api.nvim_create_augroup('reload-changed-files', { clear = true }),
  command = 'silent! checktime',
})
