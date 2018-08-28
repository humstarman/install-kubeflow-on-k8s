SHELL=/bin/bash
APP_NAME=my-kubeflow
NAMESPACE=kubeflow
LOCAL_REGISTRY_IP=10.254.0.50
LOCAL_REGISTRY_PORT=5000
ANSIBLE_GROUP=k8s
PUBLIC_DOCKER_HUB=lowyard
KSONNET_VER=0.12.0
KUBEFLOW_VER=v0.1.2
LOCAL_REGISTRY=${LOCAL_REGISTRY_IP}:${LOCAL_REGISTRY_PORT}
INGRESS_NAME=${APP_NAME}

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

cp:
	@find ./manifests -type f -name "*.sed" | sed s?".sed"?""?g | xargs -I {} cp {}.sed {}

sed:
	@find ./manifests -type f -name "*.yaml" | xargs sed -i s?"{{.name}}"?"${INGRESS_NAME}"?g
	@find ./manifests -type f -name "*.yaml" | xargs sed -i s?"{{.namespace}}"?"${NAMESPACE}"?g

deploy-ingress: cp sed
	@kubectl create -f ./manifests/.
