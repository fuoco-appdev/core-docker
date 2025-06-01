ROOT_CERTIFICATE="./volumes/ssl/root.crt"
ROOT_KEY="./volumes/ssl/root.key"
INTERMEDIATE_CERTIFICATE_REQUEST="./volumes/ssl/intermediate.csr"
INTERMEDIATE_CERTIFICATE="./volumes/ssl/intermediate.crt"
INTERMEDIATE_KEY="./volumes/ssl/intermediate.key"
CHAIN="./volumes/ssl/chain.crt"
PASS="./volumes/ssl/root.pass"

if ! [ -e "$PASS" ]; then
    echo "Please enter the password for your SSL key:"
    read -s SSL_PASSWORD
    echo
    echo "$SSL_PASSWORD" > "$PASS"
fi

if ! [ -e "$ROOT_KEY" ]; then
    openssl genrsa -out $ROOT_KEY 2048
    dos2unix $ROOT_KEY
fi

if ! [ -e "$ROOT_CERTIFICATE" ]; then
    openssl req -x509 -new -key $ROOT_KEY -days 3650 -out $ROOT_CERTIFICATE
    dos2unix $ROOT_CERTIFICATE
fi

if ! [ -e "$INTERMEDIATE_KEY" ]; then
    openssl genrsa -out $INTERMEDIATE_KEY 2048
    dos2unix $INTERMEDIATE_KEY
fi

if ! [ -e "$INTERMEDIATE_CERTIFICATE_REQUEST" ]; then
    echo "Create ssl key"
    openssl req -new -key $INTERMEDIATE_KEY -out $INTERMEDIATE_CERTIFICATE_REQUEST
    dos2unix $INTERMEDIATE_CERTIFICATE_REQUEST
fi

if ! [ -e "$INTERMEDIATE_CERTIFICATE" ]; then
    openssl x509 -req -in $INTERMEDIATE_CERTIFICATE_REQUEST -CA $ROOT_CERTIFICATE -CAkey $ROOT_KEY -CAcreateserial -days 1825 -out $INTERMEDIATE_CERTIFICATE
    dos2unix $INTERMEDIATE_CERTIFICATE
fi

if ! [ -e "$CHAIN" ]; then 
    cp $INTERMEDIATE_CERTIFICATE $CHAIN
fi