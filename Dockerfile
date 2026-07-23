FROM rocker/shiny:4.5.2

ENV RENV_CONFIG_AUTOLOADER_ENABLED=FALSE

COPY renv.lock /renv.lock

COPY --chmod=755 ./rocker_scripts/install_reqs.sh /rocker_scripts/install_reqs.sh
RUN /rocker_scripts/install_reqs.sh

COPY . /srv/shiny-server/