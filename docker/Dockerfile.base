FROM  cyberdojofoundation/java
LABEL maintainer=jon@jaggersoft.com

RUN apk --update add sqlite

COPY /jars/* /junit/

COPY red_amber_green.rb /usr/local/bin
