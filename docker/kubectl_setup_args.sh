while getopts c:e:gt: flag
do
    case "${flag}" in
        c) export KUBECONFIG_PATH=${OPTARG};;
        e) export ENV_FILE=${OPTARG};;
        gt) export GENERATE_TEMPLATES=${OPTARG};;
    esac
done