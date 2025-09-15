# ==================================================================
# module list
# ------------------------------------------------------------------
# python        3.7    (apt)
# pytorch       latest (pip)
# ==================================================================

FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04

ARG APT_INSTALL="apt-get install -y --no-install-recommends"
ARG PIP_INSTALL="python -m pip --no-cache-dir install --upgrade"
ARG GIT_CLONE="git clone --depth 10"

ENV HOME /root

WORKDIR $HOME

RUN rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update

ARG DEBIAN_FRONTEND=noninteractive

RUN $APT_INSTALL build-essential software-properties-common ca-certificates \
                 wget git zlib1g-dev nasm cmake

RUN add-apt-repository ppa:deadsnakes/ppa

RUN apt-get update

RUN $APT_INSTALL python3.7 python3.7-dev

RUN wget -O $HOME/get-pip.py https://bootstrap.pypa.io/get-pip.py

RUN python3.7 $HOME/get-pip.py

RUN ln -s /usr/bin/python3.7 /usr/local/bin/python3
RUN ln -s /usr/bin/python3.7 /usr/local/bin/python

RUN $PIP_INSTALL setuptools
RUN $PIP_INSTALL numpy scipy nltk lmdb cython pydantic pyhocon

RUN $PIP_INSTALL torch torchvision torchaudio 

ENV FORCE_CUDA="1"
ENV TORCH_CUDA_ARCH_LIST="Pascal;Volta;Turing"

RUN $PIP_INSTALL 'git+https://github.com/facebookresearch/detectron2.git'

RUN $APT_INSTALL libsm6 libxext6 libxrender1
RUN $PIP_INSTALL opencv-python-headless

WORKDIR $HOME
RUN $GIT_CLONE https://github.com/NVIDIA/apex.git
WORKDIR apex
RUN $PIP_INSTALL -v --global-option="--cpp_ext" --global-option="--cuda_ext" ./

WORKDIR $HOME
RUN $GIT_CLONE https://github.com/cocodataset/cocoapi.git
WORKDIR cocoapi/PythonAPI
RUN make
RUN python setup.py build_ext install

RUN $PIP_INSTALL --extra-index-url https://developer.download.nvidia.com/compute/redist nvidia-dali-cuda100

RUN python -m pip uninstall -y pillow pil jpeg libtiff libjpeg-turbo

RUN $GIT_CLONE https://github.com/libjpeg-turbo/libjpeg-turbo.git
WORKDIR libjpeg-turbo
RUN mkdir build
WORKDIR build
RUN cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=libjpeg-turbo -DWITH_JPEG8=1 ..
RUN make
RUN make install
WORKDIR libjpeg-turbo
RUN mv include/jerror.h include/jmorecfg.h include/jpeglib.h include/turbojpeg.h /usr/include
RUN mv include/jconfig.h /usr/include/x86_64-linux-gnu
RUN mv lib/*.* /usr/lib/x86_64-linux-gnu
RUN mv lib/pkgconfig/* /usr/lib/x86_64-linux-gnu/pkgconfig
RUN ldconfig

RUN CFLAGS="${CFLAGS} -mavx2" $PIP_INSTALL --force-reinstall --no-binary :all: --compile pillow-simd

WORKDIR $HOME

RUN ldconfig
RUN apt-get clean
RUN apt-get autoremove
RUN rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# Install commands
ARG APT_INSTALL="apt-get install -y --no-install-recommends"
ARG PIP_INSTALL="python -m pip --no-cache-dir install --upgrade"
ARG GIT_CLONE="git clone --depth 10"

# Better terminal support
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm-256color
RUN echo "Installing system libraries including python"
RUN apt-get update && sudo apt-get install -y \
    build-essential pkg-config git curl wget automake cmake libtool ca-certificates vim \
    software-properties-common tmux zsh fonts-powerline \
    libpng-dev libjpeg-dev exuberant-ctags \
    libsecret-1-0 libsecret-1-dev lftp zip libsm6 libxext6 libxrender-dev zlib1g-dev nasm

# Locale setting
ARG LOCALE=en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen $LOCALE
ENV LANGUAGE=$LOCALE
ENV LANG=$LOCALE

WORKDIR $HOME


### Zsh settings
# install Antigen, Oh my zsh, and plugins
RUN chsh -s /usr/bin/zsh
RUN OVERWRITE_CONFIRMATION=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN cd $HOME/.oh-my-zsh/custom/plugins && \
    git clone https://github.com/chrissicool/zsh-256color && \
    git clone https://github.com/esc/conda-zsh-completion && \
    git clone https://github.com/zsh-users/zsh-completions && \
    git clone https://github.com/zsh-users/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting && \
    cd $HOME
RUN echo "# Path to your Oh My Zsh installation."                                                              >> $HOME/.zshrc && \
    echo "export ZSH=\"\$HOME/.oh-my-zsh\""                                                                    >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "ZSH_THEME=\"sunrise\""                                                                               >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "# Which plugins would you like to load?"                                                             >> $HOME/.zshrc && \
    echo "# Standard plugins can be found in \$ZSH/plugins/"                                                   >> $HOME/.zshrc && \
    echo "# Custom plugins may be added to \$ZSH_CUSTOM/plugins/"                                              >> $HOME/.zshrc && \
    echo "# Example format: plugins=(rails git textmate ruby lighthouse)"                                      >> $HOME/.zshrc && \
    echo "# Add wisely, as too many plugins slow down shell startup."                                          >> $HOME/.zshrc && \
    echo "plugins=("                                                                                           >> $HOME/.zshrc && \
    echo "    git"                                                                                             >> $HOME/.zshrc && \
    echo "    pip"                                                                                             >> $HOME/.zshrc && \
    echo "    npm"                                                                                             >> $HOME/.zshrc && \
    echo "    python"                                                                                          >> $HOME/.zshrc && \
    echo "    docker"                                                                                          >> $HOME/.zshrc && \
    echo "    docker-compose"                                                                                  >> $HOME/.zshrc && \
    echo "    kubectl"                                                                                         >> $HOME/.zshrc && \
    echo "    zsh-256color"                                                                                    >> $HOME/.zshrc && \
    echo "    conda-zsh-completion"                                                                            >> $HOME/.zshrc && \
    echo "    zsh-completions"                                                                                 >> $HOME/.zshrc && \
    echo "    zsh-autosuggestions"                                                                             >> $HOME/.zshrc && \
    echo "    zsh-syntax-highlighting"                                                                         >> $HOME/.zshrc && \
    echo "    # cd \$HOME/custom/plugins"                                                                      >> $HOME/.zshrc && \
    echo "    # git clone https://github.com/chrissicool/zsh-256color"                                         >> $HOME/.zshrc && \
    echo "    # git clone https://github.com/esc/conda-zsh-completion"                                         >> $HOME/.zshrc && \
    echo "    # git clone https://github.com/zsh-users/zsh-completions"                                        >> $HOME/.zshrc && \
    echo "    # git clone https://github.com/zsh-users/zsh-autosuggestions"                                    >> $HOME/.zshrc && \
    echo "    # git clone https://github.com/zsh-users/zsh-syntax-highlighting"                                >> $HOME/.zshrc && \
    echo ")"                                                                                                   >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "source \$ZSH/oh-my-zsh.sh"                                                                           >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "# Set autosuggest settings"                                                                          >> $HOME/.zshrc && \
    echo "# ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=\"fg=#ff0000,bg=cyan,bold,underline\""                             >> $HOME/.zshrc && \
    echo "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=\"fg=#cccccc,bg=#333333\""                                           >> $HOME/.zshrc && \
    echo "ZSH_AUTOSUGGEST_USE_ASYNC=\"true\""                                                                  >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "# Set binding for delete word"                                                                       >> $HOME/.zshrc && \
    echo "bindkey -M main -M emacs '^H' backward-kill-word"                                                    >> $HOME/.zshrc && \
    echo "bindkey -M main -M emacs '^[[3;5~' kill-word"                                                        >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "# Set locale"                                                                                        >> $HOME/.zshrc && \
    echo "export LOCALE=en_US.UTF-8"                                                                           >> $HOME/.zshrc && \
    echo "export LANGUAGE=en_US.UTF-8"                                                                         >> $HOME/.zshrc && \
    echo "export LANG=en_US.UTF-8"                                                                             >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "# Better terminal support"                                                                           >> $HOME/.zshrc && \
    echo "export TERM=xterm-256color"                                                                          >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "# History size change"                                                                               >> $HOME/.zshrc && \
    echo "HISTSIZE=1000000"                                                                                    >> $HOME/.zshrc && \
    echo "SAVEHIST=1000000"                                                                                    >> $HOME/.zshrc && \
    echo "setopt BANG_HIST                 # Treat the '!' character specially during expansion."              >> $HOME/.zshrc && \
    echo "setopt EXTENDED_HISTORY          # Write the history file in the \":start:elapsed;command\" format." >> $HOME/.zshrc && \
    echo "setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits." >> $HOME/.zshrc && \
    echo "setopt SHARE_HISTORY             # Share history between all sessions."                              >> $HOME/.zshrc && \
    echo "setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history."            >> $HOME/.zshrc && \
    echo "setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again."              >> $HOME/.zshrc && \
    echo "setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate."           >> $HOME/.zshrc && \
    echo "setopt HIST_FIND_NO_DUPS         # Do not display a line previously found."                          >> $HOME/.zshrc && \
    echo "setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space."                     >> $HOME/.zshrc && \
    echo "setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file."               >> $HOME/.zshrc && \
    echo "setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry."                >> $HOME/.zshrc && \
    echo "setopt HIST_VERIFY               # Don't execute immediately upon history expansion."                >> $HOME/.zshrc && \
    echo "setopt HIST_BEEP                 # Beep when accessing nonexistent history."                         >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "# Terminal GPG credential input for SSH"                                                             >> $HOME/.zshrc && \
    echo "export GPG_TTY=\$(tty)"                                                                              >> $HOME/.zshrc && \
    echo ""                                                                                                    >> $HOME/.zshrc && \
    echo "alias rez=\"source ~/.zshrc\""                                                                       >> $HOME/.zshrc
SHELL ["/usr/bin/zsh", "-c", "-l"]


# Tmux settings
# install TPM and setup tmux configuration
RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
RUN echo "# history limit"                                                                                              >> $HOME/.tmux.conf  && \
    echo "set-option -g history-limit 50000"                                                                            >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# saner split pane commands"                                                                                  >> $HOME/.tmux.conf  && \
    echo "bind | split-window -h"                                                                                       >> $HOME/.tmux.conf  && \
    echo "bind - split-window -v"                                                                                       >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# reload config file"                                                                                         >> $HOME/.tmux.conf  && \
    echo "bind R source-file ~/.tmux.conf \; display \"~/.tmux.conf reloaded\""                                         >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# set 256 color"                                                                                              >> $HOME/.tmux.conf  && \
    echo "set -g default-terminal \"xterm-256color\""                                                                   >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# mouse mode"                                                                                                 >> $HOME/.tmux.conf  && \
    echo "set -g mouse on"                                                                                              >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# vim style copy mode"                                                                                        >> $HOME/.tmux.conf  && \
    echo "set-window-option -g mode-keys vi"                                                                            >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# # set title"                                                                                                >> $HOME/.tmux.conf  && \
    echo "# set-option -g set-titles on"                                                                                >> $HOME/.tmux.conf  && \
    echo "# set-option -g set-titles-string \"#S __ #{pane_current_path} __ #{pane_current_command}\""                  >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# plugin for layout saving/restart"                                                                           >> $HOME/.tmux.conf  && \
    echo "set -g @plugin 'tmux-plugins/tmux-resurrect'"                                                                 >> $HOME/.tmux.conf  && \
    echo "set -g @plugin 'tmux-plugins/tmux-continuum'"                                                                 >> $HOME/.tmux.conf  && \
    echo "set -g @continuum-restore 'on'"                                                                               >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# status bar"                                                                                                 >> $HOME/.tmux.conf  && \
    echo "set -g status-bg black"                                                                                       >> $HOME/.tmux.conf  && \
    echo "set -g status-fg white"                                                                                       >> $HOME/.tmux.conf  && \
    echo "set -g window-status-current-style fg=white,bg=black,bold"                                                    >> $HOME/.tmux.conf  && \
    echo "set -g status-interval 60"                                                                                    >> $HOME/.tmux.conf  && \
    echo "set -g status-left-length 30"                                                                                 >> $HOME/.tmux.conf  && \
    echo "set -g status-left '#[fg=green](#S) #(whoami) '"                                                              >> $HOME/.tmux.conf  && \
    echo "set -g status-right '#[fg=yellow]#(cut -d \" \" -f 1-3 /proc/loadavg)#[default] #[fg=white]%H:%M#[default]'"  >> $HOME/.tmux.conf  && \
    echo ""                                                                                                             >> $HOME/.tmux.conf  && \
    echo "# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)"                            >> $HOME/.tmux.conf  && \
    echo "run -b '~/.tmux/plugins/tpm/tpm'"                                                                             >> $HOME/.tmux.conf


### Vim settings
RUN mkdir -p $HOME/.vim/bundle $HOME/.vim/autoload $HOME/.vim_runtime/tmp_dirs
RUN curl -LSso $HOME/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
RUN echo "execute pathogen#infect('$HOME/.vim/bundle/{}')"   >> $HOME/.vimrc  && \
    echo "syntax on"                                         >> $HOME/.vimrc  && \
    echo "filetype plugin indent on "                        >> $HOME/.vimrc
RUN cd $HOME/.vim/bundle                                                      && \
    git clone --depth 1 https://github.com/junegunn/seoul256.vim              && \
    git clone --depth 1 https://github.com/pangloss/vim-javascript            && \
    git clone --depth 1 https://github.com/scrooloose/nerdcommenter           && \
    git clone --depth 1 https://github.com/godlygeek/tabular                  && \
    git clone --depth 1 https://github.com/Raimondi/delimitMate               && \
    git clone --depth 1 https://github.com/nathanaelkane/vim-indent-guides    && \
    git clone --depth 1 https://github.com/groenewege/vim-less                && \
    git clone --depth 1 https://github.com/othree/html5.vim                   && \
    git clone --depth 1 https://github.com/elzr/vim-json                      && \
    git clone --depth 1 https://github.com/bling/vim-airline                  && \
    git clone --depth 1 https://github.com/easymotion/vim-easymotion          && \
    git clone --depth 1 https://github.com/mbbill/undotree                    && \
    git clone --depth 1 https://github.com/majutsushi/tagbar                  && \
    git clone --depth 1 https://github.com/vim-scripts/EasyGrep               && \
    git clone --depth 1 https://github.com/jlanzarotta/bufexplorer            && \
    git clone --depth 1 https://github.com/kien/ctrlp.vim                     && \
    git clone --depth 1 https://github.com/scrooloose/nerdtree                && \
    git clone --depth 1 https://github.com/Xuyuanp/nerdtree-git-plugin        && \
    git clone --depth 1 https://github.com/jistr/vim-nerdtree-tabs            && \
    git clone --depth 1 https://github.com/scrooloose/syntastic               && \
    git clone --depth 1 https://github.com/tomtom/tlib_vim                    && \
    git clone --depth 1 https://github.com/marcweber/vim-addon-mw-utils       && \
    git clone --depth 1 https://github.com/vim-scripts/taglist.vim            && \
    git clone --depth 1 https://github.com/terryma/vim-expand-region          && \
    git clone --depth 1 https://github.com/tpope/vim-fugitive                 && \
    git clone --depth 1 https://github.com/airblade/vim-gitgutter             && \
    git clone --depth 1 https://github.com/fatih/vim-go                       && \
    git clone --depth 1 https://github.com/plasticboy/vim-markdown            && \
    git clone --depth 1 https://github.com/michaeljsmith/vim-indent-object    && \
    git clone --depth 1 https://github.com/terryma/vim-multiple-cursors       && \
    git clone --depth 1 https://github.com/tpope/vim-repeat                   && \
    git clone --depth 1 https://github.com/tpope/vim-surround                 && \
    git clone --depth 1 https://github.com/vim-scripts/mru.vim                && \
    git clone --depth 1 https://github.com/vim-scripts/YankRing.vim           && \
    git clone --depth 1 https://github.com/tpope/vim-haml                     && \
    git clone --depth 1 https://github.com/SirVer/ultisnips                   && \
    git clone --depth 1 https://github.com/honza/vim-snippets                 && \
    git clone --depth 1 https://github.com/derekwyatt/vim-scala               && \
    git clone --depth 1 https://github.com/christoomey/vim-tmux-navigator     && \
    git clone --depth 1 https://github.com/ekalinin/Dockerfile.vim            && \
    git clone --depth 1 https://github.com/Chiel92/vim-autoformat             && \
    # Theme
    git clone --depth 1 https://github.com/altercation/vim-colors-solarized

# Build default .vimrc
RUN curl -s https://gist.githubusercontent.com/dev-strender/8abf0d23e9293bf14d560ca7039ec2db/raw/f6ff75b49d68b601f6c1b4219e6b829df5fa85cc/default.vim >> $HOME/.vimrc

# JH extra settings
RUN echo "\"\"\" JH setups"                                                               >> $HOME/.vimrc  && \
    echo "set backspace=indent,eol,start \" let backspace delete over lines"              >> $HOME/.vimrc  && \
    echo "set pastetoggle=<F2>  \" enable paste mode"                                     >> $HOME/.vimrc  && \
    echo ""                                                                               >> $HOME/.vimrc  && \
    echo ""                                                                               >> $HOME/.vimrc  && \
    echo "\" add python exec path"                                                        >> $HOME/.vimrc  && \
    echo "let g:python3_host_prog='python3'"                                              >> $HOME/.vimrc  && \
    echo ""                                                                               >> $HOME/.vimrc  && \
    echo "\" enable mouse support"                                                        >> $HOME/.vimrc  && \
    echo "set ttymouse=xterm2"                                                            >> $HOME/.vimrc  && \
    echo "set mouse=a"                                                                    >> $HOME/.vimrc  && \
    echo ""                                                                               >> $HOME/.vimrc  && \
    echo "\" use seoul256"                                                                >> $HOME/.vimrc  && \
    echo "set background=dark"                                                            >> $HOME/.vimrc  && \
    echo "let g:seoul256_background = 233"                                                >> $HOME/.vimrc  && \
    echo "colo seoul256"                                                                  >> $HOME/.vimrc  && \
    echo ""                                                                               >> $HOME/.vimrc  && \
    echo "\" increase gitgutter max signs"                                                >> $HOME/.vimrc  && \
    echo "let g:gitgutter_max_signs=9999"                                                 >> $HOME/.vimrc  && \
    echo ""                                                                               >> $HOME/.vimrc  && \
    echo "\" NERDTree setting"                                                            >> $HOME/.vimrc  && \
    echo "let NERDTreeShowHidden=1"                                                       >> $HOME/.vimrc  && \
    echo ""                                                                               >> $HOME/.vimrc  && \
    echo "\" ctrl + arrow remapping"                                                      >> $HOME/.vimrc  && \
    echo "execute \"set <xUp>=\e[1;*A\""                                                  >> $HOME/.vimrc  && \
    echo "execute \"set <xDown>=\e[1;*B\""                                                >> $HOME/.vimrc  && \
    echo "execute \"set <xRight>=\e[1;*C\""                                               >> $HOME/.vimrc  && \
    echo "execute \"set <xLeft>=\e[1;*D\""                                                >> $HOME/.vimrc  && \
    echo ""                                                                               >> $HOME/.vimrc  && \
    echo "\" open NERDTree if no file selected"                                           >> $HOME/.vimrc  && \
    echo "autocmd StdinReadPre * let s:std_in=1"                                          >> $HOME/.vimrc  && \
    echo "autocmd VimEnter * if argc() == 0 && !exists(\"s:std_in\") | NERDTree | endif"  >> $HOME/.vimrc


# Reduce image size
RUN rm -rf /var/lib/apt/lists/*
WORKDIR $HOME
CMD ["tmux"]

