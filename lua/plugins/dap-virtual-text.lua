return {
  "theHamsta/nvim-dap-virtual-text",
  opts = { virt_text_pos = "eol" },
  config = function(_, opts)
    require("nvim-dap-virtual-text").setup(opts)
    vim.api.nvim_create_user_command("DapVirtualTextClear", function()
      require("nvim-dap-virtual-text.virtual_text").clear_virtual_text()
    end, {
      desc = "Clear all the virtual text displayed by nvim-dap-virtual-text",
      force = true,
    })
  end,
}
