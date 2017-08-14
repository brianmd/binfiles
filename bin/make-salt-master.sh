#!/bin/bash
# apt-get update
# apt-get -y install build-essential emacs24-nox curl git tmux zsh
# apt-get -y install git silversearcher-ag golang tree keychain zsh htop tmux python-software-properties zlib1g-dev exuberant-ctags
# # ruby/rbenv
# apt-get -y install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev
# git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
# curl -L https://bootstrap.saltstack.com -o ~/install_salt.sh
# sh ~/install_salt.sh -P -M

# note: don't need sudo
# apt-get install build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip


# need to load .spacemacs, .tmux.conf, .zshrc, .ssh/config
#      get .ssh key


# on minion creation, pass -A flag so can pass the salt-master ip address
# https://docs.saltstack.com/en/latest/topics/tutorials/salt_bootstrap.html
# sh /root/install_salt.sh -P -M -S git develop
# sh /root/install_salt.sh -P -M git develop

#!/bin/bash
add-apt-repository ppa:webupd8team/java -y
apt-get update
apt-get upgrade -y
apt-get -y install git vim emacs24-nox silversearcher-ag tree keychain zsh htop exuberant-ctags curl wget
git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d

# curl -L https://bootstrap.saltstack.com -o /root/install_salt.sh
# -Pip, -Master, -Syndic
# apt-get -y install develop
# sh /root/install_salt.sh -P -M

# java
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
apt-get -y install oracle-java8-installer
apt-get -y install oracle-java8-set-default

git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d

apt-get -y install zookeeperd
curl -L http://apache.claz.org/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz -o /root/zookeeper-3.4.8.tgz

wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod a+x lein
mv lein /usr/local/bin/

