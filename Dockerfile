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

# Better terminal support
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm-256color
RUN echo "Installing system libraries including python"
RUN apt-get update && apt-get install -y \
    build-essential pkg-config git curl wget automake cmake libtool ca-certificates vim \
    software-properties-common tmux zsh fonts-powerline \
    libpng-dev libjpeg-dev exuberant-ctags \
    libsecret-1-0 libsecret-1-dev lftp zip libsm6 libxext6 libxrender-dev    

# Locale setting
ARG LOCALE=ko_KR.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen $LOCALE
ENV LANGUAGE=$LOCALE
ENV LANG=$LOCALE


### Zsh settings
# install Antigen, Oh my zsh, and plugins
RUN chsh -s /usr/bin/zsh
RUN curl -L git.io/antigen > /root/.antigen.zsh
RUN echo "# Use antigen"                                                          >> /root/.zshrc  && \
    echo "source \$HOME/.antigen.zsh"                                             >> /root/.zshrc  && \
    echo ""                                                                       >> /root/.zshrc  && \
    echo "# Set locale"                                                           >> /root/.zshrc  && \
    echo "export LANG=ko_KR.UTF-8"                                                >> /root/.zshrc  && \
    echo ""                                                                       >> /root/.zshrc  && \
    echo "# Use Oh-My-Zsh"                                                        >> /root/.zshrc  && \
    echo "antigen use oh-my-zsh"                                                  >> /root/.zshrc  && \
    echo ""                                                                       >> /root/.zshrc  && \
    echo "# Set theme"                                                            >> /root/.zshrc  && \
    echo "antigen theme sunrise"                                                  >> /root/.zshrc  && \
    echo ""                                                                       >> /root/.zshrc  && \
    echo "# Set plugins"                                                          >> /root/.zshrc  && \
    echo "antigen bundle git"                                                     >> /root/.zshrc  && \
    echo "antigen bundle pip"                                                     >> /root/.zshrc  && \
    echo "antigen bundle npm"                                                     >> /root/.zshrc  && \
    echo "antigen bundle python"                                                  >> /root/.zshrc  && \
    echo "antigen bundle docker"                                                  >> /root/.zshrc  && \
    echo "antigen bundle docker-compose"                                          >> /root/.zshrc  && \
    echo "antigen bundle chrissicool/zsh-256color"                                >> /root/.zshrc  && \
    echo "antigen bundle esc/conda-zsh-completion"                                >> /root/.zshrc  && \
    echo "antigen bundle zsh-users/zsh-completions"                               >> /root/.zshrc  && \
    echo "antigen bundle zsh-users/zsh-autosuggestions"                           >> /root/.zshrc  && \
    echo "antigen bundle zsh-users/zsh-syntax-highlighting"                       >> /root/.zshrc  && \
    echo ""                                                                       >> /root/.zshrc  && \
    echo "# Set autosuggest settings"                                             >> /root/.zshrc  && \
    echo "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=\"fg=#ff00ff,bg=cyan,bold,underline\""  >> /root/.zshrc  && \
    echo "ZSH_AUTOSUGGEST_USE_ASYNC=\"true\""                                     >> /root/.zshrc  && \
    echo ""                                                                       >> /root/.zshrc  && \
    echo "# Set binding for delete word"                                          >> /root/.zshrc  && \
    echo "bindkey -M main -M emacs '^H' backward-kill-word"                       >> /root/.zshrc  && \
    echo "bindkey -M main -M emacs '^[[3;5~' kill-word"                           >> /root/.zshrc  && \
    echo ""                                                                       >> /root/.zshrc  && \
    echo "# Apply changes"                                                        >> /root/.zshrc  && \
    echo "antigen apply"                                                          >> /root/.zshrc  && \
    echo ""                                                                       >> /root/.zshrc  && \
    echo "alias rez=\"source /root/.zshrc\""                                      >> /root/.zshrc
SHELL ["/usr/bin/zsh", "-c", "-l"]


# Tmux settings
# install TPM and setup tmux configuration
RUN git clone https://github.com/tmux-plugins/tpm /root/.tmux/plugins/tpm
RUN echo "# history limit"                                                                                              >> /root/.tmux.conf  && \
    echo "set-option -g history-limit 50000"                                                                            >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# saner split pane commands"                                                                                  >> /root/.tmux.conf  && \
    echo "bind | split-window -h"                                                                                       >> /root/.tmux.conf  && \
    echo "bind - split-window -v"                                                                                       >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# reload config file"                                                                                         >> /root/.tmux.conf  && \
    echo "bind R source-file ~/.tmux.conf \; display \"~/.tmux.conf reloaded\""                                         >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# set 256 color"                                                                                              >> /root/.tmux.conf  && \
    echo "set -g default-terminal \"xterm-256color\""                                                                   >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# mouse mode"                                                                                                 >> /root/.tmux.conf  && \
    echo "set -g mouse on"                                                                                              >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# vim style copy mode"                                                                                        >> /root/.tmux.conf  && \
    echo "set-window-option -g mode-keys vi"                                                                            >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# # set title"                                                                                                >> /root/.tmux.conf  && \
    echo "# set-option -g set-titles on"                                                                                >> /root/.tmux.conf  && \
    echo "# set-option -g set-titles-string \"#S __ #{pane_current_path} __ #{pane_current_command}\""                  >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# plugin for layout saving/restart"                                                                           >> /root/.tmux.conf  && \
    echo "set -g @plugin 'tmux-plugins/tmux-resurrect'"                                                                 >> /root/.tmux.conf  && \
    echo "set -g @plugin 'tmux-plugins/tmux-continuum'"                                                                 >> /root/.tmux.conf  && \
    echo "set -g @continuum-restore 'on'"                                                                               >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# status bar"                                                                                                 >> /root/.tmux.conf  && \
    echo "set -g status-bg black"                                                                                       >> /root/.tmux.conf  && \
    echo "set -g status-fg white"                                                                                       >> /root/.tmux.conf  && \
    echo "set -g window-status-current-bg white"                                                                        >> /root/.tmux.conf  && \
    echo "set -g window-status-current-fg black"                                                                        >> /root/.tmux.conf  && \
    echo "set -g window-status-current-attr bold"                                                                       >> /root/.tmux.conf  && \
    echo "set -g status-interval 60"                                                                                    >> /root/.tmux.conf  && \
    echo "set -g status-left-length 30"                                                                                 >> /root/.tmux.conf  && \
    echo "set -g status-left '#[fg=green](#S) #(whoami) '"                                                              >> /root/.tmux.conf  && \
    echo "set -g status-right '#[fg=yellow]#(cut -d \" \" -f 1-3 /proc/loadavg)#[default] #[fg=white]%H:%M#[default]'"  >> /root/.tmux.conf  && \
    echo ""                                                                                                             >> /root/.tmux.conf  && \
    echo "# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)"                            >> /root/.tmux.conf  && \
    echo "run -b '~/.tmux/plugins/tpm/tpm'"                                                                             >> /root/.tmux.conf


### Vim settings
RUN mkdir -p /root/.vim/bundle /root/.vim/autoload /root/.vim_runtime/tmp_dirs
RUN curl -LSso /root/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
RUN echo "execute pathogen#infect('/root/.vim/bundle/{}')"   >> /root/.vimrc  && \
    echo "syntax on"                                         >> /root/.vimrc  && \
    echo "filetype plugin indent on "                        >> /root/.vimrc
RUN cd /root/.vim/bundle                                                      && \
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
RUN curl -s https://gist.githubusercontent.com/dev-strender/8abf0d23e9293bf14d560ca7039ec2db/raw/f6ff75b49d68b601f6c1b4219e6b829df5fa85cc/default.vim >> /root/.vimrc

# JH extra settings
RUN echo "\"\"\" JH setups"                                                               >> /root/.vimrc  && \
    echo "set backspace=indent,eol,start \" let backspace delete over lines"              >> /root/.vimrc  && \
    echo "set pastetoggle=<F2>  \" enable paste mode"                                     >> /root/.vimrc  && \
    echo ""                                                                               >> /root/.vimrc  && \
    echo ""                                                                               >> /root/.vimrc  && \
    echo "\" add python exec path"                                                        >> /root/.vimrc  && \
    echo "let g:python3_host_prog='python3'"                                              >> /root/.vimrc  && \
    echo ""                                                                               >> /root/.vimrc  && \
    echo "\" enable mouse support"                                                        >> /root/.vimrc  && \
    echo "set ttymouse=xterm2"                                                            >> /root/.vimrc  && \
    echo "set mouse=a"                                                                    >> /root/.vimrc  && \
    echo ""                                                                               >> /root/.vimrc  && \
    echo "\" use seoul256"                                                                >> /root/.vimrc  && \
    echo "set background=dark"                                                            >> /root/.vimrc  && \
    echo "let g:seoul256_background = 233"                                                >> /root/.vimrc  && \
    echo "colo seoul256"                                                                  >> /root/.vimrc  && \
    echo ""                                                                               >> /root/.vimrc  && \
    echo "\" increase gitgutter max signs"                                                >> /root/.vimrc  && \
    echo "let g:gitgutter_max_signs=9999"                                                 >> /root/.vimrc  && \
    echo ""                                                                               >> /root/.vimrc  && \
    echo "\" NERDTree setting"                                                            >> /root/.vimrc  && \
    echo "let NERDTreeShowHidden=1"                                                       >> /root/.vimrc  && \
    echo ""                                                                               >> /root/.vimrc  && \
    echo "\" ctrl + arrow remapping"                                                      >> /root/.vimrc  && \
    echo "execute \"set <xUp>=\e[1;*A\""                                                  >> /root/.vimrc  && \
    echo "execute \"set <xDown>=\e[1;*B\""                                                >> /root/.vimrc  && \
    echo "execute \"set <xRight>=\e[1;*C\""                                               >> /root/.vimrc  && \
    echo "execute \"set <xLeft>=\e[1;*D\""                                                >> /root/.vimrc  && \
    echo ""                                                                               >> /root/.vimrc  && \
    echo "\" open NERDTree if no file selected"                                           >> /root/.vimrc  && \
    echo "autocmd StdinReadPre * let s:std_in=1"                                          >> /root/.vimrc  && \
    echo "autocmd VimEnter * if argc() == 0 && !exists(\"s:std_in\") | NERDTree | endif"  >> /root/.vimrc


# Reduce image size
RUN rm -rf /var/lib/apt/lists/*
WORKDIR /root
CMD ["tmux"]

