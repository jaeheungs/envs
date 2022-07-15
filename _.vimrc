syntax on " enable highlighting
set number " enable line numbers

set backspace=indent,eol,start " let backspace delete over lines

set autoindent " enable auto indentation of lines
set smartindent " allow vim to best-effort guess the indentation
set pastetoggle=<F2> " enable paste mode

" set indent for 4 spaces
set tabstop=4
set shiftwidth=4
set expandtab

" add python exec path
let g:python3_host_prog='~/anaconda3/bin/python3'

" enable mouse support
set ttymouse=xterm2
set mouse=a

" tab control
nnoremap <C-j> :tabprevious<CR>
nnoremap <C-k> :tabnext<CR>

" vim plug
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')
Plug 'junegunn/seoul256.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'airblade/vim-gitgutter'
Plug 'Valloric/YouCompleteMe'
" Plug 'elzr/vim-json'
Plug 'Chiel92/vim-autoformat'
call plug#end()
" PlugInstall

" use seoul256
set background=dark
let g:seoul256_background = 233
colo seoul256

"" limelight highlighting
"let g:limelight_default_coefficient = 0.7
"autocmd VimEnter * Limelight

" increase gitgutter max signs
let g:gitgutter_max_signs=9999

" NERDTree setting
let NERDTreeShowHidden=1

" ctrl + arrow remapping
execute "set <xUp>=\e[1;*A" 
execute "set <xDown>=\e[1;*B"
execute "set <xRight>=\e[1;*C"
execute "set <xLeft>=\e[1;*D"

" open NERDTree if no file selected
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" statusline
set laststatus=2
function! GitBranch()
  return system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

function! StatuslineGit()
  let l:branchname = GitBranch()
  return strlen(l:branchname) > 0?'  '.l:branchname.' ':''
endfunction

set statusline=
set statusline+=%#PmenuSel#
set statusline+=%{StatuslineGit()}
set statusline+=%#LineNr#
set statusline+=\ %f
set statusline+=%m\ [0x%8.8B]
set statusline+=%=
set statusline+=%#PmenuSel#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %p%%
set statusline+=\ %l:%c
set statusline+=\


