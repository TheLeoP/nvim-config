return {
  {
    "ianding1/leetcode.vim",
    init = function()
      vim.g.leetcode_browser = "chrome"
      vim.g.leetcode_hide_paid_only = 1
      vim.g.leetcode_solution_filetype = "golang"
    end,
  },
}
