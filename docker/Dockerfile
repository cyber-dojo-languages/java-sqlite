FROM       cyberdojofoundation/java_junit
MAINTAINER Jon Jagger <jon@jaggersoft.com>

# install sqlite
RUN apk --update add sqlite

# install jar
COPY sqlite-jdbc-3.8.11.2.jar /junit/

COPY red_amber_green.rb /usr/local/bin
