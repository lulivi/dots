" Syntax colors
syntax on

" Whitespaces
set listchars=eol:$,tab:>-,trail:·,extends:>,precedes:<,space:·
set list

command TrimWhitespace :%s/\s\+$//e

" Line numbers
set number
nmap <C-N><C-N> :set invnu<CR>:set invlist<CR>

" Tabs
set expandtab
set tabstop=4
set shiftwidth=4

" 80 column mark
set colorcolumn=80
highlight ColorColumn ctermbg=darkgray

" Folding
set nofoldenable "enable with zc

" Scroll wheel navigating
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" Load vim-plug
if !empty(glob("~/.local/share/nvim/site/autoload/plug.vim"))

    call plug#begin('~/.vim/plugged')
    " Git wrapper
    Plug 'tpope/vim-fugitive'
    " Line up text
    Plug 'godlygeek/tabular'
    " Markdown stuff
    Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
    Plug 'mzlogin/vim-markdown-toc'
    Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }}
    " Rename files
    Plug 'danro/rename.vim'
    " Project tree
    Plug 'scrooloose/nerdtree'
    call plug#end()

else

    :echo "Not installed plug"
    " 'curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif


