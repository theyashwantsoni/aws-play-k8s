FROM node:alpine
MAINTAINER Yashwant Soni<yashwantsoni009@gmail.com>

ADD ./app /opt/webapp/

WORKDIR /opt/webapp
COPY . .
RUN npm install
CMD [ "npm", "start" ]
