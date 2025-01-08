return {
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find Files (cwd)" },
    { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Grep (cwd)" },
  },
}
