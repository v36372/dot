set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'mileszs/ack.vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'tpope/vim-commentary'
Plugin 'junegunn/goyo.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'tpope/vim-fugitive'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'tpope/vim-markdown'
Plugin 'vim-airline/vim-airline'
Plugin 'tpope/vim-surround'
Plugin 'xolox/vim-misc'
Plugin 'fatih/vim-go'
Plugin 'elzr/vim-json'
Plugin 'majutsushi/tagbar'
Plugin 'jiangmiao/auto-pairs'
Plugin 'airblade/vim-gitgutter'
Plugin 'gregsexton/MatchTag'
Plugin 'xolox/vim-easytags'
Plugin 'nanotech/jellybeans.vim'
Plugin 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all'  }
       "
Plugin 'junegunn/fzf.vim'
Plugin 'christoomey/vim-tmux-navigator'
call vundle#end()
filetype plugin indent on
filetype indent on

syntax enable
set background=dark

scriptencoding utf-8
set modelines=0
colorscheme jellybeans
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
set cursorline

nnoremap / /\v
vnoremap / /\v
set ignorecase
set smartcase
set gdefault
set incsearch
set showmatch
set hlsearch
set mouse=a
set list
set listchars=tab:\|\ 

let mapleader = ","

nnoremap <leader>n :NERDTreeToggle<cr>
nnoremap <leader>f :NERDTreeFind<cr>

" copy to buffer
vmap <C-c> :w! ~/.vimbuffer<CR>
nmap <C-c> :.w! ~/.vimbuffer<CR>
" paste from buffer
map <C-v> :r ~/.vimbuffer<CR>

cnoreabbrev Ack Ack!
nnoremap <Leader>a :Ack!<Space>

nmap <F4> :TagbarToggle<CR>

let NERDTreeShowHidden=1
let NERDTreeIgnore = ['\.pyc$','\.swp$', '\.un\~$', '\.DS_Store$']

au FileType go nmap ge <Plug>(go-rename)
au FileType go nmap gr <Plug>(go-referrers)
au FileType go nmap gi <Plug>(go-install)
au FileType go nmap <Leader>v <Plug>(go-def-vertical)
au FileType go nmap <Leader>s <Plug>(go-def-split)

let g:go_fmt_command = "goimports"

" Python modifications
" Smart indenting
autocmd FileType python setlocal smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
" Wrap at 72 chars for comments.
autocmd FileType python setlocal formatoptions=cq textwidth=79 foldignore= wildignore+=*.py[co]
"Indentation for Python
autocmd FileType python setlocal shiftwidth=4 tabstop=4 softtabstop=4

" Easytags setup
" Set Easytags to save to .tags in the local folder
set tags=./tags
" Create the local tag file if not exist
let g:easytags_dynamic_files=2
" Run Easytags async
let g:easytags_async=1
au FileType *.go,*.js,*.py,*.rb,*.php BufWritePost UpdateTags
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

Plugin 'wakatime/vim-wakatime'

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

function! ProseMode()
	call goyo#execute(0, [])
	set spell noci nosi noai nolist noshowmode noshowcmd
	set complete+=s
endfunction

command! ProseMode call ProseMode()
nmap \p :ProseMode<CR>

if executable('ag')
	let g:ackprg = 'ag --vimgrep'
endif
