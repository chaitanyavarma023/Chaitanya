FROM ubuntu:16.04

RUN apt update
RUN apt upgrade -y
RUN apt install -y build-essential curl devscripts gawk gcc-multilib gengetopt gettext git groff file flex libncurses5-dev libssl-dev python2.7 subversion unzip vim-common zlib1g-dev wget sharutils parallel jq device-tree-compiler u-boot-tools mtd-utils git git-gui ocaml-nox ccrypt
RUN apt install -y repo

ARG user
ARG uid
ARG gid
# addgroup --system --gid 1005 harshal3
# adduser --system --uid 1005 --gid 1005 harshal3
RUN addgroup --system --gid $gid $user
RUN adduser --system --uid $uid --gid $gid $user

RUN echo 'TZ="GMT-5:30"' >> /etc/profile

#COPY setup-all.sh /bin/setup-all.sh
#RUN chmod a+x /bin/setup-all.sh

USER $user

RUN mkdir -p /home/$user/workdir
WORKDIR /home/$user/workdir
