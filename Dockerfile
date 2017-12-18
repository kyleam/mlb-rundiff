FROM jrnold/rstan
MAINTAINER Kyle Meyer <kyle@kyleam.com>

# Assure popcon doesn't kick in
RUN bash -c "echo 'debconf debconf/frontend select noninteractive' | debconf-set-selections -"

RUN apt-get update && \
    apt-get install -y python3-docopt python3-pytest dos2unix snakemake && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN install2.r --error --deps TRUE directlabels && \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds

RUN rm -rf /tmp/* /var/tmp/* /boot /media /mnt /srv

RUN mkdir -p /opt/
WORKDIR /opt
RUN git clone --recursive https://github.com/kyleam/mlb-rundiff.git
WORKDIR /opt/mlb-rundiff

ENTRYPOINT ["/usr/bin/snakemake"]
