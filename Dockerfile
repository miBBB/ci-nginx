FROM nginx:1.25-alpine
COPY index.html /usr/share/nginx/html/index.html
RUN echo "<!-- CI Build: $(date) -->" >> /usr/share/nginx/html/index.html
EXPOSE 80
