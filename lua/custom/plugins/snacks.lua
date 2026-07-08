-- [[ snacks.nvim ]]
-- A collection of small, independent UI/UX modules. Everything is
-- opt-in: only the modules enabled below are activated, so this won't
-- touch telescope, neo-tree, fidget, etc.
--  See https://github.com/folke/snacks.nvim

vim.pack.add { 'https://github.com/folke/snacks.nvim' }

require('snacks').setup {
  -- Subtle, always-on polish
  indent = { enabled = true }, -- indent guides + animated current-scope highlight
  scroll = { enabled = true }, -- smooth, animated scrolling
  animate = { enabled = true }, -- animation engine the other modules build on
  scope = { enabled = true }, -- scope detection (underpins indent/dim)

  -- The "cool" stuff
  dashboard = {
    enabled = true, -- startup splash screen (shows on `nvim` with no file)
    -- Override the default sections: the built-in "startup" section requires
    -- `lazy.stats` (lazy.nvim), but this config uses vim.pack, so drop it.
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      { text = { '⚡ Neovim ' .. tostring(vim.version()), hl = 'footer' }, align = 'center', padding = 1 },
      {
        section = 'terminal',
        -- Installed from source (gitlab.com/phoneybadger/pokemon-colorscripts), not on PATH,
        -- hence python3 + full path. Trailing sleep lets the terminal flush before snacks
        -- captures the output.
        cmd = 'python3 ~/.local/share/pokemon-colorscripts/pokemon-colorscripts.py -r --no-title; sleep .1',
        random = 10, -- vary the cache key so a different pokemon shows each launch
        pane = 2,
        indent = 4,
        height = 30,
      },
    },
  },
  notifier = { enabled = true }, -- pretty notification toasts (fidget only does LSP progress, so no overlap)
  dim = { enabled = true }, -- dim code outside the current scope
  zen = { enabled = true }, -- distraction-free centered mode
  scratch = { enabled = true }, -- persistent, per-project scratch buffers
}

-- Nvim 0.11+ shows "[Process exited 0]" as extmark virtual text, which snacks'
-- built-in scrubber (it deletes buffer lines) can't remove — clear it under the
-- dashboard's pokemon terminal section. Scoped to dashboard buffers so regular
-- :terminal keeps the message.
vim.api.nvim_create_autocmd('TermClose', {
  callback = function(ev)
    if vim.bo[ev.buf].filetype ~= 'snacks_dashboard' then
      return
    end
    -- schedule: the default nvim.terminal TermClose handler that adds the
    -- extmark may not have run yet
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        vim.api.nvim_buf_clear_namespace(ev.buf, vim.api.nvim_create_namespace 'nvim.terminal.exitmsg', 0, -1)
      end
    end)
  end,
})

-- Zen mode toggle. `dim` is automatic (dims as you move); to turn it off
-- in a session run `:lua Snacks.dim.disable()`.
vim.keymap.set('n', '<leader>z', function() require('snacks').zen() end, { desc = 'Toggle [Z]en mode' })
vim.keymap.set('n', '<leader>tn', function() require('snacks').notifier.show_history() end, { desc = '[T]oggle [N]otification history' })

-- Scratch buffers: toggle the current project/filetype scratch, or pick one.
vim.keymap.set('n', '<leader>.', function() require('snacks').scratch() end, { desc = 'Toggle scratch buffer' })
vim.keymap.set('n', '<leader>S', function() require('snacks').scratch.select() end, { desc = 'Select [S]cratch buffer' })
