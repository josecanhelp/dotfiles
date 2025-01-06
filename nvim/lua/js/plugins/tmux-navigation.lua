return {
  "christoomey/vim-tmux-navigator",
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left with tmux" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down with tmux" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up with tmux" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right with tmux" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate previous with tmux" },
  },
}