set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'mileszs/ack.vim'
Plugin 'kien/ctrlp.vim'
Plugin 'bling/vim-airline'
Plugin 'Valloric/YouCompleteMe'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree'
Plugin 'tpope/vim-fugitive'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'digitaltoad/vim-jade'
Plugin 'groenewege/vim-less'
Plugin 'tpope/vim-markdown'
Plugin 'powerline/powerline'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-surround'
Plugin 'xolox/vim-misc'
Plugin 'fatih/vim-go'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'pangloss/vim-javascript'
Plugin 'ejamesc/JavaScript-Indent'
Plugin 'elzr/vim-json'
Plugin 'majutsushi/tagbar'
Plugin 'jiangmiao/auto-pairs'
Plugin 'othree/yajs.vim', { 'for': 'javascript' }
Plugin 'airblade/vim-gitgutter'
Plugin 'gregsexton/MatchTag'
Plugin 'xolox/vim-easytags'
Plugin 'morhetz/gruvbox'
Plugin 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all'  }
Plugin 'junegunn/fzf.vim'
call vundle#end()
filetype plugin indent on
filetype indent on

syntax enable
set background=dark

scriptencoding utf-8
set modelines=0
colorscheme gruvbox
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

nnoremap <leader>nt :NERDTreeToggle<cr>

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

"display type information for word under cursor
au FileType go nmap <Leader>i <Plug>(go-info)
"Displays interfaces that are implemented by word under cursor
au FileType go nmap <Leader>n <Plug>(go-implements)
au FileType go nmap <Leader>e <Plug>(go-rename)
au FileType go nmap <Leader>r <Plug>(go-referrers)

let g:go_fmt_command = "goimports"

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

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

" Powerline settings
let g:Powerline_symbols = 'fancy'

function! s:swap_lines(n1, n2)
    let line1 = getline(a:n1)
    let line2 = getline(a:n2)
    call setline(a:n1, line2)
    call setline(a:n2, line1)
endfunction

function! s:swap_up()
    let n = line('.')
    if n == 1
        return
    endif

    call s:swap_lines(n, n - 1)
    exec n - 1
endfunction

function! s:swap_down()
    let n = line('.')
    if n == line('$')
        return
    endif

    call s:swap_lines(n, n + 1)
    exec n + 1
endfunction

noremap <silent> <c-k> :call <SID>swap_up()<CR>
noremap <silent> <c-j> :call <SID>swap_down()<CR>

"Split options
set splitbelow
set splitright

let g:ctrlp_custom_ignore = {
  \  'dir': '(Godeps|vendor)$',
  \  'file': '\w*[\/]tags$',
  \ }

map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <A-]> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

