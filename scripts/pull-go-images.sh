#!/bin/sh
set -e
show_help () {
cat << USAGE
usage: $0 [ -d DOCKER-IMAGE(S) ] [ -i LOCAL-DOCKER-REGISTRY-IP ] [ -p LOCAL-DOCKER-REGISTRY-PROT ] 
          [ -u PUBLIC-DOCKER-HUB-PREFIX ] [ -g ANSIBLE-GROUP ]
    -d : Specify the image(s) to pull. If multiple, set the images in term of csv, 
         as 'image-1,image-2,image-3'.
    -i : Specify the IP address of local docker registry. 
    -p : Specify the port used by local docker registry. If not specified, use '5000' by default.
    -u : Specify the prefix fo docker hub. If not specified, use 'lowyard' by default.
    -g : Specify the group used by ansible. If not specified, use 'all' by default.
USAGE
exit 0
}
[ -z "$*" ] && show_help
# Get Opts
while getopts "hd:i:p:g:u:" opt; do # 选项后面的冒号表示该选项需要参数
    case "$opt" in
    h)  show_help
        ;;
    d)  IMAGES=$OPTARG # 参数存在$OPTARG中
        ;;
    i)  LOCAL_REGISTRY_IP=$OPTARG
        ;;
    p)  LOCAL_REGISTRY_PORT=$OPTARG
        ;;
    u)  DOCKER_HUB=$OPTARG
        ;;
    g)  GROUP=$OPTARG
        ;;
    ?)  # 当有不认识的选项的时候arg为?
        echo "unkonw argument"
        exit 1
        ;;
    esac
done
chk_var () {
if [ -z "$2" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no input for \"$1\", try \"$0 -h\"."
  sleep 3
  exit 1
fi
}
chk_var -i $LOCAL_REGISTRY_IP
chk_install () {
if [ ! -x "$(command -v $1)" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no $1 installed !!!"
  sleep 3
  exit 1
fi
}
NEEDS="docker ansible"
for NEED in $NEEDS; do
  chk_install $NEED
done
DOCKER_HUB=${DOCKER_HUB:-"lowyard"}
GROUP=${GROUP:-"all"}
LOCAL_REGISTRY_PORT=${LOCAL_REGISTRY_PORT:-"5000"}
LOCAL_REPO=${LOCAL_REGISTRY_IP}:${LOCAL_REGISTRY_PORT}
if [ -z "$IMAGES" ]; then
  IMAGES="quay.io/datawire/ambassador:0.30.1 \
  quay.io/datawire/statsd:0.30.1
  gcr.io/kubeflow-images-public/centraldashboard:v0.2.1
  gcr.io/kubeflow/jupyterhub-k8s:v20180531-3bb991b1
  gcr.io/kubeflow-images-public/tf_operator:v0.2.0
  google/cloud-sdk:alpine
  gcr.io/cloud-solutions-group/esp-sample-app:1.0.0
  gcr.io/google_containers/spartakus-amd64:v1.0.0
  gcr.io/kubeflow/jupyterhub-k8s:1.0.1
  gcr.io/kubeflow-images-public/tf_operator:v20180226-403
  quay.io/datawire/ambassador:0.34.0
  quay.io/datawire/statsd:0.34.0
  quay.io/kubernetes_incubator/nfs-provisioner:v1.0.8
  gcr.io/kubeflow-images-public/tf-model-server-http-proxy:v20180606-9dfda4f2
  gcr.io/kubeflow-images-public/tensorflow-serving-1.7:v20180604-0da89b8a
  gcr.io/kubeflow-images-public/tensorflow-serving-1.6gpu:v20180604-0da89b8a"
fi
pull_distribute_tag() {
  NAME=${IMAGE##*/}
  #echo $NAME
  PULLABLE=${DOCKER_HUB}/$NAME 
  REPOSITORY=${PULLABLE%%:*}
  TAG=${PULLABLE##*:}
  [ -z "$TAG" ] && TAG="latest"
  if [ -n "$(docker images | grep $REPOSITORY | grep $TAG)" ]; then
    echo "$(date) - [WARN] - $IMAGE already existed."
  else
    docker pull $PULLABLE
    echo "$(date) - [INFO] - image $PULLABLE pulled."
  fi
  docker tag $PULLABLE ${LOCAL_REPO}/$NAME
  docker tag ${LOCAL_REPO}/$NAME $IMAGE
  echo "$(date) - [INFO] - rename $PULLABLE as ${LOCAL_REPO}/$NAME."
  docker push ${LOCAL_REPO}/$NAME
  echo "$(date) - [INFO] - image ${LOCAL_REPO}/$NAME pushed."
  ansible $GROUP -m shell -a "docker pull ${LOCAL_REPO}/$NAME"
  echo "$(date) - [INFO] - image ${LOCAL_REPO}/$NAME pulled at all nodes."
  ansible $GROUP -m shell -a "docker tag ${LOCAL_REPO}/$NAME $IMAGE"
  echo "$(date) - [INFO] - rename image ${LOCAL_REPO}/$NAME as ${IMAGE} at all nodes."
  ansible $GROUP -m shell -a "docker rmi ${LOCAL_REPO}/$NAME"
  echo "$(date) - [INFO] - delete temporary image ${LOCAL_REPO}/$NAME at all nodes."
}
for IMAGE in $IMAGES; do
  pull_distribute_tag $IMAGE
done
