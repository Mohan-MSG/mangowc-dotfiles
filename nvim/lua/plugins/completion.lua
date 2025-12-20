-- return {
--     {
--         "hrsh7th/nvim-cmp",
--         event = "InsertEnter",
--         dependencies = {
--             "hrsh7th/cmp-nvim-lsp",
--             "hrsh7th/cmp-path",
--             "hrsh7th/cmp-buffer",
--         },
--         config = function()
--             local cmp = require("cmp")
--
--             cmp.setup({
--                 preselect = cmp.PreselectMode.Item, -- <— preselect first item
--                 completion = { completeopt = "menu,menuone,noinsert" },
--                 window = { documentation = cmp.config.window.bordered() },
--                 mapping = cmp.mapping.preset.insert({
--                     ["<CR>"]      = cmp.mapping.confirm({ select = false }),
--                     ["<C-e>"]     = cmp.mapping.abort(),
--                     ["<C-Space>"] = cmp.mapping.complete(), -- manual trigger if you want it
--                     ["<C-n>"]     = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
--                     ["<C-p>"]     = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
--                     ["<C-f>"]     = cmp.mapping.scroll_docs(4),
--                     ["<C-u>"]     = cmp.mapping.scroll_docs(-4),
--                     ["<Tab>"]     = cmp.mapping(function(fallback)
--                         if cmp.visible() then cmp.select_next_item() else fallback() end
--                     end, { "i", "s" }),
--                     ["<S-Tab>"]   = cmp.mapping(function()
--                         if cmp.visible() then cmp.select_prev_item() end
--                     end, { "i", "s" }),
--                 }),
--                 sources = {
--                     { name = "nvim_lsp" },
--                     { name = "path" },
--                     { name = "buffer",  keyword_length = 3 },
--                 },
--             })
--         end,
--     },
-- }
--
return {
  "saghen/blink.cmp",
  profile = true,
  version = "1.*",
  event = "LspAttach",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = "default",
      ["<Tab>"] = {
        function(cmp)
          return cmp.select_and_accept()
        end,
        "fallback",
      },

      ["<C-n>"] = { "snippet_forward" },
      ["<C-j>"] = { "select_next" },
      ["<C-k>"] = { "select_prev" },
      ["<C-p>"] = { "snippet_backward" },
    },
    appearance = {
      nerd_font_variant = "normal",
    },

sources = {
  default = { "lsp", "path", "buffer", "snippets" },
},
    completion = {
      menu = { border = "rounded", scrollbar = false },
      ghost_text = {
        enabled = true,
      },
      documentation = {
        window = { border = "rounded", scrollbar = true },
        auto_show = true,
        auto_show_delay_ms = 500,
      },
    },
    signature = {
      enabled = false,
      trigger = { enabled = true },
      window = {
        scrollbar = false,
        border = "rounded",
        show_documentation = true,
      },
    },
    fuzzy = {
      implementation = "rust",
    },
  },
  opts_extend = { "sources.default" },
}
