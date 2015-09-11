#! /usr/bin/env bash

# for linux
sudo apt-get remove -y --purge vim vim-runtime vim-gnome vim-tiny vim-common vim-gui-common

sudo apt-get build-dep
 
sudo apt-get install -y lua5.1 liblua5.1-dev python-dev ruby-dev libperl-dev mercurial libncurses5-dev

sudo rm -rf /usr/local/share/vim

sudo rm /usr/bin/vim
 
sudo mkdir /usr/include/lua5.1/include
sudo mkdir /usr/include/lua5.1/lib
sudo ln -s /usr/include/lua5.1/*.h /usr/include/lua5.1/include/
sudo ln -s /usr/lib/x86_64-linux-gnu/liblua5.1.so /usr/include/lua5.1/lib/liblua.so
 
cd ~
wget ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2
tar jxf vim-7.4.tar.bz2
cd vim74
./configure --with-features=huge \
            --enable-rubyinterp \
            --enable-largefile \
            --disable-netbeans \
            --enable-pythoninterp \
            --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
            --enable-perlinterp \
            --enable-luainterp \
            --enable-gui=auto \
            --enable-fail-if-missing \
            --with-lua-prefix=/usr/include/lua5.1 \
            --enable-cscope 
make 
sudo make install
