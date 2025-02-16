NGINX_CERTIFICATE_REQUEST="../volumes/nginx/domain.csr"
NGINX_CERTIFICATE="../volumes/nginx/domain.crt"
NGINX_KEY="../volumes/nginx/domain.key"
NGINX_PASS="../volumes/nginx/domain.pass"

if ! [ -e "$NGINX_PASS" ]; then
    echo "Please enter the password for your SSL key:"
    read -s SSL_PASSWORD
    echo
    echo "$SSL_PASSWORD" > "$NGINX_PASS"
fi

if ! [ -e "$NGINX_KEY" ]; then
    openssl genrsa -out $NGINX_KEY 2048
    dos2unix $NGINX_KEY
fi

if ! [ -e "$NGINX_CERTIFICATE_REQUEST" ]; then
    echo "Create NGINX ssl key"
    openssl req -new -key $NGINX_KEY -out $NGINX_CERTIFICATE_REQUEST
    dos2unix $NGINX_CERTIFICATE_REQUEST
fi

if ! [ -e "$NGINX_CERTIFICATE" ]; then
    openssl x509 -req -days 365 -signkey $NGINX_KEY -in $NGINX_CERTIFICATE_REQUEST -req -out $NGINX_CERTIFICATE
    dos2unix $NGINX_CERTIFICATE
fi