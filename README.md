# Mobashi-ROUT

Server ROUT of the Mobashi system.

# Installation

## Configuration for localdev

Only the first time, init Django models and create superuser, running the following commands while __inside__ the running devcontainer:

    cd /workspaces/mobashi-rout/mobashi-rout
    ../django_init.sh

## Configuration for prod

Only the first time, init Django models and create superuser, running the following commands while __outside__ the running devcontainer:

    sudo docker compose up -d
    sudo docker compose exec mobashi-rout /bin/bash
    ./django_init.sh

## Rebuilding

Anytime something changes in the image, for example something file __requirements.txt__, use following command to rebuild:

    sudo docker compose down
    sudo docker compose build
    sudo docker compose up -d

## For local pgrouting

If usage of local pgrouting is needed, a suitable Database must be accessible and can be created using:

    https://github.com/amat-mi/amat-osmtools-docker

# Useful commands

Start all the services:

    sudo docker compose up -d

Opn a shell into running container for "mobashi-rout" service:

    sudo docker compose exec mobashi-rout /bin/bash
