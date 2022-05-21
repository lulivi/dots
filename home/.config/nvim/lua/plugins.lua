return require("packer").startup(function()
    use({
        'wbthomason/packer.nvim',
        config = function() require 'plugins' end,
    })
    -- Zen mode for undisrupted work environment
    use({
        "folke/zen-mode.nvim",
        config = function()
            require("zen-mode").setup({
                window = {
                    width = 120,
                    height = 1,
                    options = {
                        number = false,
                        relativenumber = false,
                        list = false,
                        colorcolumn = "",
                    },
                },
            })
        end,
    })

    -- Colorschemes
    use({
        "RRethy/nvim-base16",
        config = function()
            vim.cmd("colorscheme base16-dracula")
        end,
    })

    -- Languages
    use({
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "bash", "c", "lua", "python" },
                highlight = { enable = true },
            })
        end,
    })

    -- Explorer
    use({
        "kyazdani42/nvim-tree.lua",
        config = function()
            require("nvim-tree").setup({
                view = { side = "left", width = 30 },
            })
        end,
    })
end)
