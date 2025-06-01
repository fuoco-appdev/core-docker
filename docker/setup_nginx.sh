if [ -n "$ENV_FILE" ]; then
    echo "Skipping nginx env setup"
else
    ENV_FILE=".env"
    source ./load_env.sh
fi

IFS=' ' read -ra STACK_ARRAY <<< "$STACKS"

export host="\$host" server_port="\$server_port" http_x_csrf_token="\$http_x_csrf_token" http_authorization="\$http_authorization" http_cookie="\$http_cookie" remote_addr="\$remote_addr" proxy_add_x_forwarded_for="\$proxy_add_x_forwarded_for" scheme="\$scheme" http_upgrade="\$http_upgrade" connection_upgrade="\$connection_upgrade"

if [[ "${STACK_ARRAY[@]}" =~ "core" ]]; then
    export NGINX_CORE_HTTP_CONFIG="include /etc/nginx/conf.d/http/core.conf;"
    export NGINX_CORE_STREAM_CONFIG="include /etc/nginx/conf.d/stream/core.conf;"
    envsubst < ./volumes/nginx/conf.d/http/core.conf.template > ./volumes/nginx/conf.d/http/core.conf
    envsubst < ./volumes/nginx/conf.d/stream/core.conf.template > ./volumes/nginx/conf.d/stream/core.conf
else
    echo "Skipping nginx core config"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ecommerce" ]]; then
    export NGINX_ECOMMERCE_HTTP_CONFIG="include /etc/nginx/conf.d/http/ecommerce.conf;"
    envsubst < ./volumes/nginx/conf.d/http/ecommerce.conf.template > ./volumes/nginx/conf.d/http/ecommerce.conf
else
    echo "Skipping nginx ecommerce config"
fi

if [[ "${STACK_ARRAY[@]}" =~ "ai" ]]; then
    export NGINX_AI_HTTP_CONFIG="include /etc/nginx/conf.d/http/ai.conf;"
    envsubst < ./volumes/nginx/conf.d/http/ai.conf.template > ./volumes/nginx/conf.d/http/ai.conf
else
    echo "Skipping nginx ai config"
fi

if [[ "${STACK_ARRAY[@]}" =~ "blog" ]]; then
    export NGINX_BLOG_HTTP_CONFIG="include /etc/nginx/conf.d/http/blog.conf;"
    envsubst < ./volumes/nginx/conf.d/http/blog.conf.template > ./volumes/nginx/conf.d/http/blog.conf
else
    echo "Skipping nginx blog config"
fi

envsubst < ./volumes/nginx/nginx.conf.template > ./volumes/nginx/nginx.conf