if [ "$OS" = "Linux" ]; then
    echo "This is Linux"

    #Install envsubst
    curl -L https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst-`uname -s`-`uname -m` -o envsubst
    chmod +x envsubst
    sudo mv envsubst /usr/local/bin

    # Download and execute the Helm installation script
    echo "Downloading Helm installation script..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    # Make the script executable
    echo "Making the script executable..."
    chmod 700 get_helm.sh
    # Install Helm
    echo "Installing Helm..."
    ./get_helm.sh

    # Check if Helm was installed correctly
    if command_exists helm; then
        echo "Helm has been installed successfully."
        helm version  # Output Helm version to confirm installation
    else
        echo "Helm installation failed. Please check the logs above for errors."
        exit 1
    fi

    # Install htpasswd if it's not already installed
    npm install -g htpasswd

    # Cleanup
    echo "Cleaning up installation script..."
    rm get_helm.sh
elif [ "$(uname)" == "Darwin" ]; then
    #Install envsubst
    curl -O https://ftp.gnu.org/gnu/gettext/gettext-latest.tar.gz
    tar xzf gettext-latest.tar.gz
    cd gettext-*

    ./configure --prefix=/usr/local
    make
    sudo make install

    #Install helm
    brew install helm

    npm install -g htpasswd
elif [ "$OS" = "MINGW"* ] || [ "$OS" = "MSYS"* ]; then
    # On Windows, if you're using Git Bash or MSYS2, `uname -s` might return MINGW or MSYS
    echo "This is Windows"

    #Install envsubst
    curl -L https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst.exe -o envsubst.exe

    #Install helm
    winget install Helm.Helm

    npm install -g htpasswd
else
    echo "This is an unknown OS or not supported"

    #Install envsubst
    curl -L https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst.exe -o envsubst.exe

    #Install helm
    winget install Helm.Helm

    npm install -g htpasswd
fi