#!/bin/bash
set -e
show_help () {
cat << USAGE
usage: $0 [ -n NAME ] [ -s NAMESPACE ] [ -v VERSION ]
    -v : Specify the version of the software. 
    -n : Specify the name of this app. 
    -s : Specify the namespace of this app. 
         If not specified, use "default" by default.
USAGE
exit 0
}
# Get Opts
while getopts "hv:n:s:" opt; do # 选项后面的冒号表示该选项需要参数
    case "$opt" in
    h)  show_help
        ;;
    v)  VERSION=$OPTARG
        ;;
    n)  NAME=$OPTARG
        ;;
    s)  NAMESPACE=$OPTARG
        ;;
    ?)  # 当有不认识的选项的时候arg为?
        echo "unkonw argument"
        exit 1
        ;;
    esac
done
[ -z "$*" ] && show_help
chk_var () {
if [ -z "$2" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no input for \"$1\", try \"$0 -h\"."
  sleep 3
  exit 1
fi
}
chk_var -v $VERSION
chk_var -n $NAME
NAMESPACE=${NAMESPACE:-"default"}
if [ ! -x "$(command -v ks)" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no ks installed!"
  sleep 3
  exit 1
fi
# Create a namespace for kubeflow deployment
[[ $(kubectl get namespace | grep ${NAMESPACE}) ]] || kubectl create namespace ${NAMESPACE}

# Which version of Kubeflow to use
# For a list of releases refer to:
# https://github.com/kubeflow/kubeflow/releases
#VERSION=v0.1.2

# Initialize a ksonnet app. Set the namespace for it's default environment.
ks init ${NAME}

# mk deplyment script
cat > ${NAME}/run.sh << EOF
#!/bin/bash
set -e
show_help () {
cat << USAGE
usage: $0 [ -n NAME ] [ -s NAMESPACE ] [ -v VERSION ]
    -v : Specify the version of the software. 
    -n : Specify the name of this app. 
    -s : Specify the namespace of this app. 
         If not specified, use "default" by default.
USAGE
exit 0
}
# Get Opts
while getopts "hv:" opt; do # 选项后面的冒号表示该选项需要参数
    case "$opt" in
    h)  show_help
        ;;
    v)  VERSION=$OPTARG
        ;;
    n)  NAME=$OPTARG
        ;;
    s)  NAMESPACE=$OPTARG
        ;;
    ?)  # 当有不认识的选项的时候arg为?
        echo "unkonw argument"
        exit 1
        ;;
    esac
done
[ -z "$*" ] && show_help
chk_var () {
if [ -z "$2" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no input for \"$1\", try \"$0 -h\"."
  sleep 3
  exit 1
fi
}
chk_var -v $VERSION
chk_var -n $NAME
NAMESPACE=${NAMESPACE:-"default"}

# Create a namespace for kubeflow deployment
#NAMESPACE=kubeflow
#kubectl create namespace ${NAMESPACE}

# Which version of Kubeflow to use
# For a list of releases refer to:
# https://github.com/kubeflow/kubeflow/releases
#VERSION=${VERSION}

# Initialize a ksonnet app. Set the namespace for it's default environment.
#NAME=my-kubeflow
#ks init ${NAME}
#cd ${NAME}
ks env set default --namespace ${NAMESPACE}

# Install Kubeflow components
ks registry add kubeflow github.com/kubeflow/kubeflow/tree/${VERSION}/kubeflow

ks pkg install kubeflow/core@${VERSION}
ks pkg install kubeflow/tf-serving@${VERSION}
ks pkg install kubeflow/tf-job@${VERSION}

# Create templates for core components
ks generate kubeflow-core kubeflow-core

# If your cluster is running on Azure you will need to set the cloud parameter.
# If the cluster was created with AKS or ACS choose aks, it if was created
# with acs-engine, choose acsengine
# PLATFORM=<aks|acsengine>
# ks param set kubeflow-core cloud ${PLATFORM}

# Enable collection of anonymous usage metrics
# Skip this step if you don't want to enable collection.
ks param set kubeflow-core reportUsage true
ks param set kubeflow-core usageId $(uuidgen)

# Deploy Kubeflow
ks apply default -c kubeflow-core
EOF
chmod +x ${NAME}/run.sh
