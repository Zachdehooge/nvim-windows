-- Suppress "require('lspconfig') is deprecated" warning
local orig_notify = vim.notify
vim.notify = function(msg, ...)
  if type(msg) == "string" and msg:match("require%(\'lspconfig\'%)") then
    return
  end
  orig_notify(msg, ...)
end

-- Diagnostics
vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = false,
	signs = true,
	underline = true,
	update_in_insert = false,
})

-- Load nvchad defaults
require("nvchad.configs.lspconfig").defaults()

-- LSP setup
local nvlsp = require("nvchad.configs.lspconfig")
local lspconfig = require("lspconfig")  -- required for setup()
local util = require("lspconfig/util")

-- Servers with default config
local servers = { "html", "cssls" }
for _, server_name in ipairs(servers) do
	lspconfig[server_name].setup({
		on_attach = nvlsp.on_attach,
		on_init = nvlsp.on_init,
		capabilities = nvlsp.capabilities,
	})
end

-- Terraform
local tf_capb = vim.lsp.protocol.make_client_capabilities()
tf_capb.textDocument.completion.completionItem.snippetSupport = true
lspconfig.terraformls.setup({
	on_attach = nvlsp.on_attach,
	flags = { debounce_text_changes = 150 },
	capabilities = tf_capb,
})

-- Go
lspconfig.gopls.setup({
	on_attach = nvlsp.on_attach,
	capabilities = nvlsp.capabilities,
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_dir = util.root_pattern("go.work", "go.mod", ".git"),
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
			analyses = { unusedparams = true },
		},
	},
})

-- Python
lspconfig.pyright.setup({
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "off",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
			},
		},
	},
})

-- Rust
lspconfig.rust_analyzer.setup({
	settings = {
		["rust-analyzer"] = {
			inlayHints = { enable = true },
		},
	},
})

-- Auto-disable virtual_text and virtual_lines on LspAttach
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function()
		vim.diagnostic.config({
			virtual_text = false,
			virtual_lines = false,
			signs = true,
			underline = true,
			update_in_insert = false,
		})
	end,
})

-- Custom diagnostic handler: disable virtual_text globally
vim.diagnostic.handlers.virtual_text = {
	show = function() end,
	hide = function() end,
}
