FROM nginx:alpine
RUN ln -sf /proc/1/fd/1 /var/log/nginx/access.log \
  && ln -sf /proc/1/fd/2 /var/log/nginx/error.log
COPY nginx.conf /etc/nginx/nginx.conf
COPY upstream-defs.conf /etc/nginx/upstream-defs.conf
RUN rm /etc/nginx/conf.d/*
RUN mkdir /nginx_cache
EXPOSE 7997 7998 7999 8000 8001 8002