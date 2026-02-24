DOCKER_RUNTIME=podman
DEPLOYMENT_NAME=stt-hello-world-jms
IMAGE_NAME=quay.io/staillanibm/msr-hello-world-jms
TAG=1.0.2

DOCKER_PORT_NUMBER=16643
DOCKER_ROOT_URL=https://localhost:$(DOCKER_PORT_NUMBER)
DOCKER_ADMIN_PASSWORD=$(shell grep '^ADMIN_PASSWORD=' ./resources/docker-compose/.env | cut -d'=' -f2)

KUBE_NAMESPACE=iwhi
KUBE_ROOT_URL=https://$(shell oc get route stt-hello-world-jms-api -n $(KUBE_NAMESPACE) -o jsonpath='{.spec.host}')
KUBE_TEST_PASSWORD=$(shell oc get secret stt-hello-world-jms -n $(KUBE_NAMESPACE) -o jsonpath='{.data.TESTER_PASSWORD}' | base64 -d)

docker-build:
	$(DOCKER_RUNTIME) build -t $(IMAGE_NAME):$(TAG) --platform=linux/amd64 .

docker-login-whi:
	@echo ${WHI_CR_PASSWORD} | $(DOCKER_RUNTIME) login ${WHI_CR_SERVER} -u ${WHI_CR_USERNAME} --password-stdin

docker-login-gh:
	@echo ${GH_CR_PASSWORD} | $(DOCKER_RUNTIME) login ${GH_CR_SERVER} -u ${GH_CR_USERNAME} --password-stdin

docker-push:
	$(DOCKER_RUNTIME) push $(IMAGE_NAME):$(TAG)

docker-run:
	IMAGE_NAME=${IMAGE_NAME} TAG=${TAG} DEPLOYMENT_NAME=$(DEPLOYMENT_NAME) DOCKER_PORT_NUMBER=$(DOCKER_PORT_NUMBER) $(DOCKER_RUNTIME) compose -f ./resources/docker-compose/docker-compose.yml up -d

docker-stop:
	IMAGE_NAME=${IMAGE_NAME} TAG=${TAG} DEPLOYMENT_NAME=$(DEPLOYMENT_NAME) DOCKER_PORT_NUMBER=$(DOCKER_PORT_NUMBER) $(DOCKER_RUNTIME) compose -f ./resources/docker-compose/docker-compose.yml down

docker-logs:
	$(DOCKER_RUNTIME) logs $(DEPLOYMENT_NAME)

docker-logs-f:
	$(DOCKER_RUNTIME) logs -f $(DEPLOYMENT_NAME)

docker-test:
	@curl -X POST $(DOCKER_ROOT_URL)/helloworld/messages \
    -u Administrator:$(DOCKER_ADMIN_PASSWORD) \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"content": "Hello", "createdBy": "tester"}' -k

ocp-login:
	@oc login ${OCP_API_URL} -u ${OCP_USERNAME} -p ${OCP_PASSWORD}

helm-install-wm-repo:
	helm repo add webmethods-official https://ibm.github.io/webmethods-helm-charts/charts

helm-update-wm-repo:
	helm repo update webmethods-official 

helm-search-wm-repo:
	helm search repo webmethods-official

kube-deploy-ems:
	kubectl apply -f ./resources/helm/msr-secrets.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-ca-issuer.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-service-certificate.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-egress-tibcoems.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-service-api.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-route-admin.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-route-api.yaml -n $(KUBE_NAMESPACE)
	helm upgrade --install stt-hello-world-jms webmethods-official/microservicesruntime -n $(KUBE_NAMESPACE) -f ./resources/helm/msr-values-ems.yaml --set image.repository=$(IMAGE_NAME) --set image.tag=$(TAG)

kube-deploy-um:
	kubectl apply -f ./resources/helm/msr-secrets.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-ca-issuer.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-service-certificate.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-egress-tibcoems.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-service-api.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-route-admin.yaml -n $(KUBE_NAMESPACE)
	kubectl apply -f ./resources/helm/msr-route-api.yaml -n $(KUBE_NAMESPACE)
	helm upgrade --install stt-hello-world-jms webmethods-official/microservicesruntime -n $(KUBE_NAMESPACE) -f ./resources/helm/msr-values-um.yaml --set image.repository=$(IMAGE_NAME) --set image.tag=$(TAG)

kube-test:
	@curl -k -X POST $(KUBE_ROOT_URL)/helloworld/messages \
    -u tester:$(KUBE_TEST_PASSWORD) \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"content": "Hello Kube", "createdBy": "Stéphane"}'

kube-restart:
	kubectl rollout restart deployment $(DEPLOYMENT_NAME) -n $(KUBE_NAMESPACE)

kube-get-pods:
	kubectl get pods -l app=$(DEPLOYMENT_NAME) -n $(KUBE_NAMESPACE)

kube-logs-f:
	kubectl logs -l app=$(DEPLOYMENT_NAME) -n $(KUBE_NAMESPACE) --all-containers=true -f --prefix

