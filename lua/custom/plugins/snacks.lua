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
  quickfile = { enabled = true }, -- render the file before heavier plugins load when opening `nvim file`
  statuscolumn = { enabled = true }, -- tidy left column: line numbers + git/diagnostic signs + folds

  -- The "cool" stuff
  dashboard = {
    enabled = true, -- startup splash screen (shows on `nvim` with no file)
    preset = {
      -- The default keys minus the lazy.nvim-only entries (Lazy UI, session
      -- restore — no persistence.nvim installed), plus a scratch-buffer key.
      keys = {
        { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
        { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
        { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = '󰎞 ', key = '.', desc = 'Scratch Buffer', action = function() Snacks.scratch() end },
        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
      },
    },
    -- Override the default sections: the built-in "startup" section requires
    -- `lazy.stats` (lazy.nvim), but this config uses vim.pack, so drop it.
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      { text = { '⚡ Neovim ' .. tostring(vim.version()), hl = 'footer' }, align = 'center', padding = 1 },
      { pane = 2, icon = ' ', title = 'Recent Files', section = 'recent_files', limit = 5, cwd = true, indent = 2, padding = 1 },
      {
        pane = 2,
        icon = ' ',
        title = 'Git Status',
        section = 'terminal',
        enabled = function() return Snacks.git.get_root() ~= nil end,
        cmd = 'git status --short --branch --renames',
        height = 6,
        padding = 1,
        ttl = 5 * 60,
        indent = 3,
      },
      {
        pane = 2,
        icon = ' ',
        title = 'Open PRs',
        section = 'terminal',
        enabled = function() return Snacks.git.get_root() ~= nil end,
        -- Fallback text matters twice over: `gh pr list` emits ZERO bytes when
        -- there are no PRs (an all-empty pty renders as a stray cursor glyph),
        -- and snacks only caches non-empty output. Errors (no GitHub remote,
        -- no gh auth) are suppressed and fall through to the same message.
        cmd = 'prs="$(gh pr list -L 3 2>/dev/null)"; echo "${prs:-No open PRs}"',
        height = 4,
        padding = 1,
        ttl = 15 * 60, -- network call; cache a bit longer than git status
        indent = 3,
      },
      {
        -- pane 1, listed last: sits centered below the header/keys/footer
        -- column. The script picks a random gen-1 pokemon and centers it to
        -- the dashboard width (see scripts/dashboard-pokemon.sh).
        section = 'terminal',
        cmd = vim.fn.stdpath 'config' .. '/scripts/dashboard-pokemon.sh 60',
        random = 10, -- vary the cache key so a different pokemon shows each launch
        height = 22, -- tallest gen-1 small sprite
      },
    },
  },
  notifier = { enabled = true }, -- pretty notification toasts (fidget only does LSP progress, so no overlap)
  dim = { enabled = true }, -- dim code outside the current scope
  zen = { enabled = true }, -- distraction-free centered mode
  scratch = { enabled = true }, -- persistent, per-project scratch buffers
}

-- Dashboard palette: catppuccin mocha, to complement the tmux status line
-- (same hex values as the @thm_* vars in catppuccin/tmux). Mauve is the tmux
-- accent; icons/keys pick up the module colors the status bar uses. The rest
-- of the editor stays gruvbox.
local mocha = {
  mauve = '#cba6f7',
  blue = '#89b4fa',
  green = '#a6e3a1',
  peach = '#fab387',
  overlay = '#9399b2',
}
local function dashboard_hl()
  vim.api.nvim_set_hl(0, 'SnacksDashboardHeader', { fg = mocha.mauve })
  vim.api.nvim_set_hl(0, 'SnacksDashboardTitle', { fg = mocha.mauve, bold = true })
  vim.api.nvim_set_hl(0, 'SnacksDashboardSpecial', { fg = mocha.mauve })
  vim.api.nvim_set_hl(0, 'SnacksDashboardIcon', { fg = mocha.blue })
  vim.api.nvim_set_hl(0, 'SnacksDashboardKey', { fg = mocha.peach })
  vim.api.nvim_set_hl(0, 'SnacksDashboardDir', { fg = mocha.overlay })
  vim.api.nvim_set_hl(0, 'SnacksDashboardFooter', { fg = mocha.overlay })
end
dashboard_hl()
-- reapply after any :colorscheme, which would otherwise wipe these groups
vim.api.nvim_create_autocmd('ColorScheme', { callback = dashboard_hl })

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

-- Zen lives in the <leader>t toggle group. `dim` is automatic (dims as you
-- move); to turn it off in a session run `:lua Snacks.dim.disable()`.
vim.keymap.set('n', '<leader>tz', function() require('snacks').zen() end, { desc = '[T]oggle [Z]en mode' })
vim.keymap.set('n', '<leader>tn', function() require('snacks').notifier.show_history() end, { desc = '[T]oggle [N]otification history' })

-- Scratch buffers: <leader>. is the scratch prefix — double-tap to toggle the
-- current project/filetype scratch, .s to pick from all of them.
vim.keymap.set('n', '<leader>..', function() require('snacks').scratch() end, { desc = 'Toggle scratch buffer' })
vim.keymap.set('n', '<leader>.s', function() require('snacks').scratch.select() end, { desc = '[S]elect scratch buffer' })
require('which-key').add { { '<leader>.', group = 'Scratch' } }
