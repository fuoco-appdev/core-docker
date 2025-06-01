# Path to the password file
HTPASSWD_FILE="./volumes/nginx/.htpasswd"

# Function to add or create user
add_user() {
    local username=$1
    local password=$2
    local create_flag=""

    # Check if the file exists
    if [ ! -f "$HTPASSWD_FILE" ]; then
        create_flag="-c"
    fi

    # Use htpasswd to add or create user with user input
    npx htpasswd $create_flag "$HTPASSWD_FILE" "$username"
}

if ! [ -e "$HTPASSWD_FILE" ]; then
    echo "Create NGINX user"
    read -p "Enter username (or press Enter to finish): " username
    # Securely read password
    read -s -p "Enter password for $username: " password
    echo  # Add a newline after password input for better UX
        
    # Add or create user
    add_user "$username" "$password"

    echo "User $username added to $HTPASSWD_FILE"
fi