SHELL=/bin/bash
KSONNET_VER=0.12.0
KUBEFLOW_VER=v0.1.2
NAMESPACE=kubeflow
APP_NAME=my-kubeflow
LOCAL_REGISTRY_IP=10.254.0.50
LOCAL_REGISTRY_PORT=5000
LOCAL_REGISTRY=${LOCAL_REGISTRY_IP}:${LOCAL_REGISTRY_PORT}
PUBLIC_DOCKER_HUB=lowyard
ANSIBLE_GROUP=k8s

all: deploy-ks config get-image deploy-kubeflow
install: all

deploy-ks:
	@./scripts/get-ksonnet.sh -v ${KSONNET_VER}

config:
	@yes | cp ./scripts/config.sh ./
	@./config.sh -v ${KUBEFLOW_VER} -n ${APP_NAME} -s ${NAMESPACE}
	@ rm -f ./config.sh

get-image:
	@./scripts/pull-go-images.sh -i ${LOCAL_REGISTRY_IP} -p ${LOCAL_REGISTRY_PORT} -u ${PUBLIC_DOCKER_HUB} -g ${ANSIBLE_GROUP} 

deploy-kubeflow:
	@cd ${APP_NAME} && ./run.sh

clean:
	@ks delete ${APP_NAME}
	@kubectl delete -namespace ${NAMESPACE}
