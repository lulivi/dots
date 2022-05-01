require("plugins")

local set = vim.opt
local g = vim.g

-- ######## ##     ## ##    ##  ######        ##     ## ######## #### ##        ######
-- ##       ##     ## ###   ## ##    ##       ##     ##    ##     ##  ##       ##    ##
-- ##       ##     ## ####  ## ##             ##     ##    ##     ##  ##       ##
-- ######   ##     ## ## ## ## ##             ##     ##    ##     ##  ##        ######
-- ##       ##     ## ##  #### ##             ##     ##    ##     ##  ##             ##
-- ##       ##     ## ##   ### ##    ##       ##     ##    ##     ##  ##       ##    ##
-- ##        #######  ##    ##  ######         #######     ##    #### ########  ######

function map(mode, shortcut, command)
    vim.api.nvim_set_keymap(mode, shortcut, command,
                            {noremap = true, silent = true})
end

function nmap(shortcut, command) map("n", shortcut, command) end

function command(name, command)
    vim.api.nvim_create_user_command(name, command, {})
end

function autocmd(group_name, event, pattern, callback)
    vim.api.nvim_create_autocmd(event, {
        group = group,
        pattern = pattern,
        callback = callback
    })
end

function highlight(group, color)
    vim.api.nvim_set_hl(0, group, {
        cterm = color.style or "NONE",
        ctermbg = color.bg or "NONE",
        ctermfg = color.fg or "NONE"
    })
end

--    ###    ##     ## ########  #######  ##     ##    ###    ######## ####  ######
--   ## ##   ##     ##    ##    ##     ## ###   ###   ## ##      ##     ##  ##    ##
--  ##   ##  ##     ##    ##    ##     ## #### ####  ##   ##     ##     ##  ##
-- ##     ## ##     ##    ##    ##     ## ## ### ## ##     ##    ##     ##  ##
-- ######### ##     ##    ##    ##     ## ##     ## #########    ##     ##  ##
-- ##     ## ##     ##    ##    ##     ## ##     ## ##     ##    ##     ##  ##    ##
-- ##     ##  #######     ##     #######  ##     ## ##     ##    ##    ####  ######

autocmd("packer_user_config", "BufWritePost", "plugins.lua", function(args)
    nvim_exec(":source " .. args.file .. " | PackerCompile")
end)
autocmd("nvim_user_config", "BufWritePost", "init.lua",
        function(args) nvim_exec(":source " .. args.file) end)

--  ######   #######  ##     ## ##     ##    ###    ##    ## ########   ######
-- ##    ## ##     ## ###   ### ###   ###   ## ##   ###   ## ##     ## ##    ##
-- ##       ##     ## #### #### #### ####  ##   ##  ####  ## ##     ## ##
-- ##       ##     ## ## ### ## ## ### ## ##     ## ## ## ## ##     ##  ######
-- ##       ##     ## ##     ## ##     ## ######### ##  #### ##     ##       ##
-- ##    ## ##     ## ##     ## ##     ## ##     ## ##   ### ##     ## ##    ##
--  ######   #######  ##     ## ##     ## ##     ## ##    ## ########   ######

command("TrimWhitespace", "%s/\\s\\+$//e")
command("CReload", ":source ~/.config/nvim/init.lua")
command("CEdit", ":e ~/.config/nvim/init.lua")
command("PEdit", ":e ~/.config/nvim/lua/plugins.lua")

-- ##     ##    ###    ########   ######
-- ###   ###   ## ##   ##     ## ##    ##
-- #### ####  ##   ##  ##     ## ##
-- ## ### ## ##     ## ########   ######
-- ##     ## ######### ##              ##
-- ##     ## ##     ## ##        ##    ##
-- ##     ## ##     ## ##         ######

-- Formating
nmap("<C-R><C-L>", ":silent !stylua %<CR>")
nmap("<C-R><C-P>", ":silent !black %<CR>")

-- Numbers
nmap("<C-S><C-S>", ":set invlist<CR>")
nmap("<C-N><C-N>", ":set invrnu<CR>:set invnu<CR>")

-- nvim-tree
nmap("<C-T><C-T>", ":NvimTreeToggle<CR>")
nmap("<C-T><C-O>", ":NvimTreeOpen<CR>")
nmap("<C-T><C-F>", ":NvimTreeFindFile<CR>")

--  ######   #######  ##    ## ######## ####  ######
-- ##    ## ##     ## ###   ## ##        ##  ##    ##
-- ##       ##     ## ####  ## ##        ##  ##
-- ##       ##     ## ## ## ## ######    ##  ##   ####
-- ##       ##     ## ##  #### ##        ##  ##    ##
-- ##    ## ##     ## ##   ### ##        ##  ##    ##
--  ######   #######  ##    ## ##       ####  ######

-- Invisible characters
set.listchars = "eol:$,tab:<->,extends:>,precedes:<,nbsp:%,trail:·,space:·"
set.list = true

-- Line numbers
set.rnu = true
set.nu = true

-- Tabs vs Spaces
set.expandtab = true
set.tabstop = 4
set.shiftwidth = 4
set.smartindent = true
set.textwidth = 100

set.colorcolumn = "80,100"
highlight("ColorColumn", {style = "reverse"})

-- Statusline
set.laststatus = 2
-- Symbols:
-- %* - reset colors to default
-- %{1,9}* - User{1,9} colors
-- %F - full path file name
-- %l - line number
-- %P - line percentage
-- %c - column number
set.statusline = string.format("%s%%1* %%= %%*%s", "%2* %F %*",
                               "%3* w-%{wordcount().words} :: l-%l (%P), c-%c %*")
highlight("User1", {fg = "1", bg = "0"})
highlight("User2", {fg = "Black", bg = "LightYellow"})
highlight("User3", {fg = "Black", bg = "LightBlue"})

-- Builtins
g.loaded_gzip = false
g.loaded_netrwPlugin = false
g.loaded_netrwSettngs = false
g.loaded_netrwFileHandlers = false
g.loaded_tar = false
g.loaded_tarPlugin = false
g.zipPlugin = false
g.loaded_zipPlugin = false
g.loaded_2html_plugin = false
g.loaded_remote_plugins = false
set.shadafile = "NONE"
