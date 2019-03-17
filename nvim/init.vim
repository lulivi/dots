syntax on
set number
set colorcolumn=80
highlight ColorColumn ctermbg=gray
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" Load vim-plug
if empty(glob("~/.local/share/nvim/site/autoload/plug.vim"))
    execute 'curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-fugitive'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown', { 'for': 'markdown' }
Plug 'danro/rename.vim'
call plug#end()

