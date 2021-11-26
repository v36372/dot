set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'mileszs/ack.vim'
Plugin 'scrooloose/nerdcommenter'

Plugin 'scrooloose/nerdtree'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-markdown'
Plugin 'tpope/vim-surround'
Plugin 'fatih/vim-go'
Plugin 'elzr/vim-json'
Plugin 'majutsushi/tagbar'
Plugin 'jiangmiao/auto-pairs'
Plugin 'airblade/vim-gitgutter'
" Plugin 'gregsexton/MatchTag'
Plugin 'xolox/vim-easytags'
Plugin 'xolox/vim-misc'
Plugin 'nanotech/jellybeans.vim'
Plugin 'morhetz/gruvbox'
Plugin 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all'  }
"
Plugin 'junegunn/fzf.vim'
Plugin 'christoomey/vim-tmux-navigator'
Plugin 'easymotion/vim-easymotion'
Plugin 'haya14busa/incsearch.vim'
Plugin 'derekwyatt/vim-scala'
Plugin 'tell-k/vim-autopep8'
Plugin 'ceedubs/sbt-ctags'
Plugin 'sainnhe/gruvbox-material'
Plugin 'gkapfham/vim-vitamin-onec'
Plugin 'atahabaki/archman-vim'
Plugin 'ycm-core/YouCompleteMe'

" Plugin 'terryma/vim-smooth-scroll'


" Set to autoread when a file is changed from the outside
set autoread
set autowrite

" Fast saving
nmap <leader>w :w!<cr>

call vundle#end()
filetype plugin indent on
filetype indent on

syntax enable
set background=dark

scriptencoding utf-8
set modelines=0
colorscheme odyssey
set autoindent noexpandtab tabstop=4 shiftwidth=4
set encoding=utf-8
set scrolloff=7
set showmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
set visualbell
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2
set relativenumber
set undofile
set exrc
set secure
set noswapfile

nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
if has('mouse')
	set mouse=a
endif


" Map jj to Esc -> Type jj in INSERT mode to back to NORMAL mode
:imap jj <Esc>

set list
set listchars=tab:\|\ 

let mapleader = ","

set autoindent		" always set autoindenting on
set si " smart indent


" Convenient command to see the difference between the current buffer and the
" " file it was loaded from, thus the changes you made.
" " Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
  			  \ | wincmd p | diffthis
endif

" Always show statusline
set laststatus=2

nnoremap <leader>n :NERDTreeToggle<cr>
nnoremap <leader>f :NERDTreeFind<cr>

vmap <leader>y "*y
noremap <leader>p "*p
noremap <leader>Y "+y
noremap <leader>P "+p

cnoreabbrev Ack Ack!
nnoremap <Leader>a :Ack!<Space>
nnoremap <leader>d H:call EasyMotion#WB(0, 0)<CR>
nnoremap <leader>w H:call EasyMotion#WB(0, 0)<CR>

nmap <F4> :TagbarToggle<CR>

let NERDTreeShowHidden=1
let NERDTreeIgnore = ['\.pyc$','\.swp$', '\.un\~$', '\.DS_Store$', '\tags']
let NERDTreeWinSize=30

""""""""
" NERDCommenter
" " Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
"" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" Map Ctrl + / as commenter toggle
nmap <C-_>   <Plug>NERDCommenterToggle
vmap <C-_>   <Plug>NERDCommenterToggle<CR>gv

au FileType go nmap ge <Plug>(go-rename)
au FileType go nmap gr <Plug>(go-referrers)
au FileType go nmap gi <Plug>(go-install)
au FileType go nmap <Leader>v <Plug>(go-def-vertical)
au FileType go nmap <Leader>s <Plug>(go-def-split)

let g:go_fmt_command = "goimports"

au FileType python nmap <leader>v :vsp <CR>:exec("YcmCompleter GoToDefinitionElseDeclaration")<CR>
au FileType python nmap <leader>s :sp <CR>:exec("YcmCompleter GoToDefinitionElseDeclaration")<CR>

" Python modifications
" Smart indenting
autocmd FileType python setlocal smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
" Wrap at 72 chars for comments.
autocmd FileType python setlocal formatoptions=cq textwidth=79 foldignore= wildignore+=*.py[co]
"Indentation for Python
autocmd FileType python setlocal shiftwidth=4 tabstop=4 softtabstop=4


" indent
au FileType yaml setlocal tabstop=2 expandtab shiftwidth=2 softtabstop=2
au FileType yml setlocal tabstop=2 expandtab shiftwidth=2 softtabstop=2
au FileType javascript setlocal tabstop=2 expandtab shiftwidth=2 softtabstop=2
au FileType pug setlocal tabstop=2 expandtab shiftwidth=2 softtabstop=2
au FileType html setlocal tabstop=2 shiftwidth=2 expandtab
au FileType vue setlocal tabstop=2 shiftwidth=2 expandtab
au FileType eruby setlocal tabstop=2 shiftwidth=2 expandtab
au FileType scss setlocal tabstop=2 shiftwidth=2 expandtab
au FileType ruby setlocal tabstop=2 shiftwidth=2 expandtab
au FileType html.erb setlocal tabstop=2 shiftwidth=2 expandtab
au FileType html.handlebars setlocal tabstop=2 expandtab shiftwidth=2 softtabstop=2k

" Easytags setup
let g:easytags_cmd = '/usr/local/bin/ctags'
" Set Easytags to save to .tags in the local folder
set tags=./tags;
set tags+=./.git/tags-dep,tags-dep,./.git/tags,tags
set tags+=tags;/

" Create the local tag file if not exist
" :let g:easytags_dynamic_files = 1
let g:easytags_dynamic_files=1
" Run Easytags async
let g:easytags_async=1
au FileType *.go,*.js,*.py,*.rb,*.php,*.scala BufWritePost UpdateTags
let g:easytags_languages = {
			\   'javascript': {
			\     'cmd': '/usr/local/bin/jsctags',
			\       'args': [],
			\       'fileoutput_opt': '-f',
			\       'stdout_opt': '-f-',
			\       'recurse_flag': '-R'
			\   }
			\}

set bs=2

"Split options
set splitbelow
set splitright

map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

" FZF
nmap <space> :Buffers<CR>
nmap <Leader>t :Files<CR>
nmap <Leader>r :Tags<CR>

" Fast import package
" Install https://github.com/haya14busa/gopkgs & fzf
"
augroup gopkgs
	autocmd!
	autocmd FileType go command! -buffer Import exe fzf#run({'source':'gopkgs', 'sink':'GoImport', 'option': 'm+', 'down': 30})
	autocmd FileType go command! -buffer Doc exe fzf#run({'source':'gopkgs', 'sink':'GoImport', 'option': 'm+', 'down': 30})
augroup END

map <Leader>i :call fzf#run({'source': 'gopkgs', 'sink':'GoImport', 'option':'m+', 'down': 30})<CR>

if executable('ag')
	let g:ackprg = 'ag --vimgrep'
endif

set nocursorline

let g:ycm_global_ycm_extra_conf = '~/global_extra_conf.py'

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

" noremap <silent> <c-u> :call smooth_scroll#up(&scroll, 2, 1)<CR>
" noremap <silent> <c-d> :call smooth_scroll#down(&scroll, 2, 1)<CR>
" noremap <silent> <c-b> :call smooth_scroll#up(&scroll*2, 0, 2)<CR>
" noremap <silent> <c-f> :call smooth_scroll#down(&scroll*2, 0, 2)<CR>

let g:rbpt_colorpairs = [
    \ ['brown',       'RoyalBlue3'],
    \ ['Darkblue',    'SeaGreen3'],
    \ ['darkgray',    'DarkOrchid3'],
    \ ['darkgreen',   'firebrick3'],
    \ ['darkcyan',    'RoyalBlue3'],
    \ ['darkred',     'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['brown',       'firebrick3'],
    \ ['gray',        'RoyalBlue3'],
    \ ['black',       'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['Darkblue',    'firebrick3'],
    \ ['darkgreen',   'RoyalBlue3'],
    \ ['darkcyan',    'SeaGreen3'],
    \ ['darkred',     'DarkOrchid3'],
    \ ['red',         'firebrick3']
	\ ]

let g:rbpt_max = 16
let g:rbpt_loadcmd_toggle = 0

nnoremap <C-X> <C-W><C-]> 
vnoremap <C-X> <C-W><C-]>
nnoremap <C-V> <C-W>v<C-]>
vnoremap <C-V> <C-W>v<C-]>


highlight Comment gui=italic

map <C-e> :!ctags -R --options=/Users/tintnguyen/.ctags.d/.ctags .<CR>
