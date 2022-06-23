FROM gradle:jdk11-focal

USER root

ARG USER_ID

RUN apt-get -y update && \
    apt-get -y upgrade && \
 apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common && \
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
 add-apt-repository \
 "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
 $(lsb_release -cs) \
 stable" && \
 apt-get update && \
 apt-get -y install git build-essential docker-ce docker-ce-cli containerd.io sudo mc net-tools openssh-server iputils-ping telnet

RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
 chmod +x /usr/local/bin/docker-compose && \
 ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

RUN curl -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

#RUN curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
#RUN chmod +x ./nodesource_setup.sh
#RUN ./nodesource_setup.sh
RUN curl -fsSL --insecure https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor | tee "/usr/share/keyrings/nodesource.gpg" >/dev/null
#RUN KEYRING=/usr/share/keyrings/nodesource.gpg gpg --no-default-keyring --keyring "$KEYRING" --list-keys
RUN echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_12.x $(lsb_release -s -c) main" | sudo tee /etc/apt/sources.list.d/nodesource.list
RUN echo "deb-src [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_12.x $(lsb_release -s -c) main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
RUN apt-get update
RUN apt-get -y install nodejs
RUN node --version

COPY entrypoint/prepare.sh /home/gradle/prepare.sh

ENTRYPOINT ["./prepare.sh",""]