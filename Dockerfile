FROM ubuntu:latest
LABEL maintainer='sunilssaini139@gmail.com'
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt install -y nginx wget curl unzip vim
COPY ./index.html /var/www/html
WORKDIR /var/www/html
EXPOSE 80/tcp
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

