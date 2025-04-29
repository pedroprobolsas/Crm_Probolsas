FROM nginx:alpine

# Copiar los archivos de la aplicación
COPY dist/ /usr/share/nginx/html/

# Copiar la configuración de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponer el puerto
EXPOSE 80

# El comando por defecto de la imagen nginx:alpine es iniciar nginx
