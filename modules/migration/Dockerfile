FROM docteurklein/sqitch
ENV PGHOST=postgresql_test \
    PGDATABASE=postgres \
    PGUSER=postgres \
    PGPASSWORD=1q2w3e4r \
    GOSU_VERSION="1.7"
ENV	PG_MAJOR 9.6
ENV PG_VERSION 9.6.1-1.pgdg80+1
COPY ./app/ /src/
RUN apt-get update \
	&& apt-get install -y apt-utils \
    && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
  && apt-get install -y libdbd-pg-perl \
  && cpan App::cpanminus \
  && cpanm DBD::Pg 
RUN groupadd -r postgres --gid=999 \ 
  && useradd -r -g postgres --uid=999 postgres  
RUN apt-get install -y --force-yes postgresql-client
ENTRYPOINT ["/bin/bash"]
