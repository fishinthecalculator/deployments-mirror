set backspace=indent,eol,start "enable backspace -.-
set ruler "cursor position on the bottom bar
set number "line numbers 

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


call plug#begin('~/.vim/plugged')

Plug 'junegunn/vim-plug'
Plug 'morhetz/gruvbox'

call plug#end()

syntax on

set background=dark
let g:gruvbox_italic=1
colorscheme gruvbox 

