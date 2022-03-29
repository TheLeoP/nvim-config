-- venn.nvim: enable or disable keymappings
function _G.Toggle_venn()
    local venn_enabled = vim.inspect(vim.b.venn_enabled)
    local notify_options = {
        title = 'Venn.nvim toggle',
        timeout = 100,
    }

    if venn_enabled == "nil" then
        vim.b.venn_enabled = true
        vim.cmd[[setlocal virtualedit=all]]
        -- draw a line on HJKL keystokes
        vim.api.nvim_buf_set_keymap(0, "n", "J", "<C-v>j:VBox<CR>", {noremap = true})
        vim.api.nvim_buf_set_keymap(0, "n", "K", "<C-v>k:VBox<CR>", {noremap = true})
        vim.api.nvim_buf_set_keymap(0, "n", "L", "<C-v>l:VBox<CR>", {noremap = true})
        vim.api.nvim_buf_set_keymap(0, "n", "H", "<C-v>h:VBox<CR>", {noremap = true})
        -- draw a box by pressing "f" with visual selection
        vim.api.nvim_buf_set_keymap(0, "v", "f", ":VBox<CR>", {noremap = true})
        vim.notify('Venn.nvim activated', vim.log.levels.INFO, notify_options)
    else
        vim.cmd[[setlocal virtualedit=]]
        vim.api.nvim_buf_set_keymap(0, "n", "J", "<nop>", {noremap = true})
        vim.api.nvim_buf_set_keymap(0, "n", "K", "<nop>", {noremap = true})
        vim.api.nvim_buf_set_keymap(0, "n", "L", "<nop>", {noremap = true})
        vim.api.nvim_buf_set_keymap(0, "n", "H", "<nop>", {noremap = true})
        vim.api.nvim_buf_set_keymap(0, "v", "f", "<nop>", {noremap = true})
        vim.b.venn_enabled = nil
        vim.notify('Venn.nvim deactivated', vim.log.levels.INFO, notify_options)
    end
end
