-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("i", "fd", "<ESC>", {})
map("i", "<C-H>", "<C-W>", { noremap = true })

map("n", "<leader><space>", "<cmd>Telescope find_files<cr>", { desc = "Find Files (cwd)", noremap = true })
map("n", "<leader>/", "<cmd>Telescope live_grep<cr>", { desc = "Grep (cwd)", noremap = true })
