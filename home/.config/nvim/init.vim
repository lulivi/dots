so $HOME/.vimrc

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

    autocmd vimenter * NERDTree

else

    :echo "Not installed plug"
    " 'curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif


