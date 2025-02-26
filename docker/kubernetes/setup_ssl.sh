# NGINX_ROOT_CERTIFICATE="../volumes/nginx/root.crt"
# NGINX_ROOT_KEY="../volumes/nginx/root.key"
# NGINX_INTERMEDIATE_CERTIFICATE_REQUEST="../volumes/nginx/intermediate.csr"
# NGINX_INTERMEDIATE_CERTIFICATE="../volumes/nginx/intermediate.crt"
# NGINX_INTERMEDIATE_KEY="../volumes/nginx/intermediate.key"
# NGINX_CHAIN="../volumes/nginx/chain.crt"
# NGINX_PASS="../volumes/nginx/domain.pass"

# if ! [ -e "$NGINX_PASS" ]; then
#     echo "Please enter the password for your SSL key:"
#     read -s SSL_PASSWORD
#     echo
#     echo "$SSL_PASSWORD" > "$NGINX_PASS"
# fi

# if ! [ -e "$NGINX_ROOT_KEY" ]; then
#     openssl genrsa -out $NGINX_ROOT_KEY 2048
#     dos2unix $NGINX_ROOT_KEY
# fi

# if ! [ -e "$NGINX_ROOT_CERTIFICATE" ]; then
#     openssl req -x509 -new -key $NGINX_ROOT_KEY -days 3650 -out $NGINX_ROOT_CERTIFICATE
#     dos2unix $NGINX_ROOT_CERTIFICATE
# fi

# if ! [ -e "$NGINX_INTERMEDIATE_KEY" ]; then
#     openssl genrsa -out $NGINX_INTERMEDIATE_KEY 2048
#     dos2unix $NGINX_INTERMEDIATE_KEY
# fi

# if ! [ -e "$NGINX_INTERMEDIATE_CERTIFICATE_REQUEST" ]; then
#     echo "Create NGINX ssl key"
#     openssl req -new -key $NGINX_INTERMEDIATE_KEY -out $NGINX_INTERMEDIATE_CERTIFICATE_REQUEST
#     dos2unix $NGINX_INTERMEDIATE_CERTIFICATE_REQUEST
# fi

# if ! [ -e "$NGINX_INTERMEDIATE_CERTIFICATE" ]; then
#     openssl x509 -req -in $NGINX_INTERMEDIATE_CERTIFICATE_REQUEST -CA $NGINX_ROOT_CERTIFICATE -CAkey $NGINX_ROOT_KEY -CAcreateserial -days 1825 -out $NGINX_INTERMEDIATE_CERTIFICATE
#     dos2unix $NGINX_INTERMEDIATE_CERTIFICATE
# fi

# if ! [ -e "$NGINX_CHAIN" ]; then 
#     cp $NGINX_INTERMEDIATE_CERTIFICATE $NGINX_CHAIN
# fi