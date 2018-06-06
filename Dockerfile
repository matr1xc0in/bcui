FROM securenginx:latest

LABEL maintainer="matr1xc0in"

USER root

ARG ETH_USER
ARG ETH_UID
ARG ETH_GID

# Configurating all necessary stuff
ENV SHELL=/bin/bash \
    ETH_USER=$ETH_USER \
    ETH_UID=$ETH_UID \
    ETH_GID=$ETH_GID \
    CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$ETH_USER

COPY update-permission /usr/local/bin/update-permission

# Setup conda for all python stuff
# Setup nodejs
RUN groupadd -g $ETH_GID $ETH_USER && \
    useradd -u $ETH_UID -g $ETH_GID -d $HOME -ms /bin/bash $ETH_USER && \
    chmod g+w /etc/passwd /etc/group ; \
    mkdir -p $CONDA_DIR ; \
    chown -R $ETH_USER:$ETH_GID $CONDA_DIR ; \    
    chown -R $ETH_USER:$ETH_GID $HOME ; \    
    update-permission $HOME && \
    update-permission $CONDA_DIR ; \
    curl --silent --location https://rpm.nodesource.com/setup_9.x | bash -

# Pre-install all required pkgs
RUN yum clean all && yum history sync && rpm --rebuilddb && \
    yum update -y && \
    yum install -y \
      nodejs \
      && yum clean all && rm -rf /var/cache/yum ; \
      rm ./package-lock.json ; rm -r ./node_modules ; \
      npm cache clear --force ; \
      npm install -g pm2

WORKDIR $HOME

# Install conda
ENV MINICONDA_VER 4.5.1
RUN cd /tmp && \
    curl -s --output Miniconda3-${MINICONDA_VER}-Linux-x86_64.sh https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VER}-Linux-x86_64.sh && \
    echo "0c28787e3126238df24c5d4858bd0744 *Miniconda3-${MINICONDA_VER}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VER}-Linux-x86_64.sh -b -f -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VER}-Linux-x86_64.sh && \
    #Install/deploy python web framework and related python mopdules \
    $CONDA_DIR/bin/conda install tornado && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy && \
    update-permission $CONDA_DIR && \
    update-permission /home/$ETH_USER

# Installing telegram bot
# RUN cd /home/$ETH_USER; git clone --depth 0 https://github.com/python-telegram-bot/python-telegram-bot --recursive && \
ADD ./python-telegram-bot.tar.gz /home/$ETH_USER/

RUN cd /home/$ETH_USER/python-telegram-bot ; python setup.py install ; \
    chown -R $ETH_USER:$ETH_GID $CONDA_DIR ; \
    chown -R $ETH_USER:$ETH_GID $HOME ; \
    update-permission $HOME && \
    update-permission $CONDA_DIR

USER $ETH_UID
