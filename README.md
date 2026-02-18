# webMethods JMS microservices

This repo showcases the use of webMethods Integration (Microservices Runtime here) to implement a Hello World JMS API:
- a message is sent to the API implementation via a request queue
- a response is returned by the API implementation via a response queue  

The API implementation in itself is very simple: 
- a newMessage JMS trigger detects the arrival of a new message in the request queue
- it triggers the execution of a processMessage flow service, passing it the JMS message
- the flow service enhances the incoming message with a uuid and a timestamp, and uses the reply public service to return the enhanced message via the reply queue  

This implementation has been tested with webMethods Universal Messaging 11.1 (over TLS) and Tibco EMS Community Edition 8.5.1 (over plain tcp.)  

To further showcase the JMS API, a wrapping REST API method is also available, via POST /messages
- the API method is associated to a sendAndWait flow service via a REST API descriptor and a REST resource
- the flow service takes in input the same message received by the request queue
- it uses the sendAndWait public service to call the JMS API
- it returns the enhanced message returned by the JMS API

The REST API specification can be found in resources/api/api.yaml

##  Makefile

A [Makefile](Makefile) is provided to build, push, deploy and test the microservice.  
Notice the variables at the top of the file, which you can adapt to your context:
```
DOCKER_RUNTIME=podman                                           # Change to docker if you're using Docker
DEPLOYMENT_NAME=stt-hello-world-jms                             # The name of the Kube deployment (and also the name of the container when deploying using docker compose)
IMAGE_NAME=ghcr.io/staillanibm/msr-hello-world-jms              # The container registry repo name in which the image is located
TAG=latest                                                      # The image tag
DOCKER_ROOT_URL=http://localhost:15555                          # The root url to call the REST API deployed via docker compose
DOCKER_ADMIN_PASSWORD=Manage123                                 # The password to call the REST API deployed via docker compose
KUBE_NAMESPACE=iwhi                                             # The kube namespace in which the microservice is deployed
KUBE_ROOT_URL=https://stt-hello-world-jms-iwhi.somewhere.com    # The root url to call the REST API deployed via kube
KUBE_ADMIN_PASSWORD=Manage12345                                 # The password to call the REST API deployed via kube
```

##  Build of the microservice image

We use a classical [Dockerfile](Dockerfile)
- we start with the official webMethods Microservices Runtime (MSR) image
- we copy the integration package that's in this repo
- we add some JMS jar files in order for the MSR to connect to Tibco EMS (the JMS jar files to connect to Universal Messaging are already included in the official product image)  

To build the image, ensure you are logged onto the icr.io repository (using your IBM entitlement key), then:
`make kube-build`

##  External configuration 

The microservice configures itself using an application.properties file, which contains placeholders for environment variables, kube secrets and vault secrets.  
The specifications for this properties file can be found [here](https://www.ibm.com/docs/en/webmethods-integration/wm-microservices-runtime/11.1.0?topic=guide-configuration-variables-template-assets)  
When deploying locally using docker / podman, we mount this file as a volume. When deploying in kube, we mount it via a config map.

##  Local deployment using Docker / podman compose

See the [docker-compose](resources/docker-compose) folder, which contains:
- the docker-compose.yml 
- the application.properties file (mounted into the container)
- an .env file that contains environment variables with secret information. An .env.example file is provided for convenience.  

The docker-compose.yml file references a jks truststore which contains the certificate presented by the JMS provider (not provided in this repo.)  

To start the deployment:
`make docker-run`

To check the logs:
`make docker-logs` or `make docker-logs-f` in tail mode.  

To test the API:
`make docker-test`

To stop the deployment:
`make docker-stop`

##  Kube deployment using Helm

See the [helm](resources/helm) folder, which contains:
- the Helm values file (msr-values.yaml), which includes amongst other things the content of the application.properties file
- the OpenShift route definition (the Helm chart can only create kube ingresses at the moment)
- the secrets neeeded for the deployment (including the jks truststore and the image pull secret)
- an egress network policy to allow outgoing connections to Tibco EMS (in case it is needed)  

To install the webMethods Helm charts:
`make helm-install-wm-repo`

To deploy the microservice:
`make kube-deploy`

To check the logs:
`make kube-logs-f`

To test the API:
`make kube-test`
