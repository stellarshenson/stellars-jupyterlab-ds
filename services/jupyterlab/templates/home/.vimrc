set nocompatible              " be iMproved, required
" set mouse=a                 " enable mouse selections, scrolling etc..
filetype off                  " required
set viminfo='1000,<10000,s1000  " increase memory to 1000 commands, 10k lines and 1000kb of text

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" markdown plugin configuration
let g:markdown_enable_spell_checking = 0
let g:markdown_enable_input_abbreviations = 0

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
Plugin 'wincent/command-t'
" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}
Plugin 'lokaltog/vim-distinguished'
Plugin 'pangloss/vim-javascript'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'sainnhe/archived-colors'
Plugin 'seesleestak/duo-mini'
Plugin 'tpope/vim-commentary'
Plugin 'gabrielelana/vim-markdown'
" Plugin 'valloric/youcompleteme'

" Highlight requirements.txt files
Plugin 'raimon49/requirements.txt.vim'
Plugin 'chrisbra/unicode.vim'


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
"colorscheme duo-mini
colorscheme distinguished 

" highlight and unhighlight search
set hlsearch
nnoremap // :nohl<CR><C-L>

" toggle comments in code
nmap <C-_> gcc
vmap <C-_> gc

set tabstop=8
set softtabstop=4
set shiftwidth=4
set nonumber

" Return to last edit position when opening files (You want this!)
 autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" map Shift-Tab to autocomplete (former Ctrl-n)
inoremap <S-Tab> <C-n>

" EOF
