FROM ubuntu:18.04

RUN echo 'deb [trusted=yes] http://download.tizen.org/tools/latest-release/Ubuntu_18.04/ /' >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y git wget curl vim ssh gbs mic python python-pip build-essential openssh-server locales && \    
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils && \
    apt-get clean

# Set the locale
# RUN apt-get install -y locales language-pack-ko
# RUN locale-gen ko_KR.UTF-8
# ENV LANG ko_KR.UTF-8
# ENV LANGUAGE ko_KR:kr
# ENV LC_ALL ko_KR.UTF-8

ENV OS_LOCALE="en_US.utf8" \
    DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y locales && locale-gen ${OS_LOCALE}
ENV LANG=${OS_LOCALE} \
    LANGUAGE=${OS_LOCALE} \
    LC_ALL=${OS_LOCALE} 

RUN apt-get autoremove -y && apt-get clean \
	&& rm -rf /var/lib/apt/lists/* 	

RUN sed -i 's/^AcceptEnv LANG LC_\*$//g' /etc/ssh/sshd_config

RUN mkdir /var/run/sshd

ADD system/sshd_config /etc/ssh/sshd_config

#ex) test_tizen 
RUN git config --global user.name "ID" 

#ex) test_tizen@gmail.com 
RUN git config --global user.email "E-MAIL" 

RUN git config --global color.ui true

RUN mkdir ~/bin/
RUN echo 'PATH=~/bin:$PATH' >> ~/.bashrc

RUN curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo && \
    chmod a+x ~/bin/repo

COPY .ssh /root/.ssh

RUN chmod 700 /root/.ssh/ && chmod 644 /root/.ssh/* && chmod 600 /root/.ssh/id_rsa

ADD repo-script/ /root/repo-script/

ADD samples/ /root/samples/

ENTRYPOINT ["/usr/sbin/sshd","-D"]
