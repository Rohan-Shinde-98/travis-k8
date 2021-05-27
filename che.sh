#!/bin/sh

PLUGIN_REGISTRY_CUSTOM_IMAGE="[server/]imageName:imageTag"
DEV_FILE_REGISTRY_CUSTOM_IMAGE="[server/]imageName:imageTag"
CHE_SERVER_CUSTOM_IMAGE="[server/]imageName:imageTag"

IFS='%'
str="\
spec:
  auth:
    updateAdminPassword: false
  server:
    cusotmCheProperties:
      CHE_WORKSPACE_SIDECAR_IMAGE_PULL__POLICY: IfNotPresent
      CHE_WORKSPACE_PLUGIN_BROKER_PULL__POLICY: IfNotPresent
      CHE_INFRA_KUBERNETES_PVC_JOBS_IMAGE_PULL__POLICY: IfNotPresent
  $(
    echo ""
 	if [ $PLUGIN_REGISTRY_CUSTOM_IMAGE ]
	then
		echo "    pluginRegistryImage: '${PLUGIN_REGISTRY_CUSTOM_IMAGE}'"	
		echo "    pluginRegistryPullPolicy: IfNotPresent"	
	fi
  if [ $DEV_FILE_REGISTRY_CUSTOM_IMAGE ]
	then
		echo "    devfileRegistryImage: '${DEV_FILE_REGISTRY_CUSTOM_IMAGE}'"	
		echo "    devfileRegistryPullPolicy: IfNotPresent"	
	fi
  if [ $CHE_SERVER_CUSTOM_IMAGE ]
	then

    #check for the image name format
    IFS=':'
    read -ra split <<< "$CHE_SERVER_CUSTOM_IMAGE"
    if [ ${#split[@]} != 2 ]
    then
      echo "che server image needs to be in format: [server/]imageName:imageTag. Found ${CHE_SERVER_CUSTOM_IMAGE}"
      exit 1
    fi
    unset IFS
    echo "    cheImage: '${split[0]}'"
    echo "    cheImageTag: ${split[1]}"
    echo "    cheImagePullPolicy: IfNotPresent"
	fi
  )"

CUSTOM_RESOURCE_PATH='/tmp/custom-resource-patch.yaml'
touch CUSTOM_RESOURCE_PATH

echo $str > $CUSTOM_RESOURCE_PATH

unset IFS

chectl server:deploy --listr-renderer=verbose --platform=minikube --che-operator-cr-patch-yaml=${CUSTOM_RESOURCE_PATH} --chenamespace=eclipse-che


echo "Eclipse Che [sets che-url]..."
getCheIngressProcess=$(kubectl get ingress che -n eclipse-che -o jsonpath='{.spec.rules[0].host}')
cheHostName=$(echo "$getCheIngressProcess"|sed "s/'//g")
cheUrl="https://${cheHostName}"

echo "Eclipse Che [sets che-token]..."
getIngressProcess=$(kubectl get ingress/keycloak -n eclipse-che -o jsonpath='{.spec.rules[0].host}')
keycloakBaseUrl=$(echo "$getIngressProcess"|sed "s/'//g")
curl -k -X POST $keycloakUrl -H Content-Type: application/x-www-form-urlencoded -d username=admin -d password=admin -d grant_type=password -d client_id=che-public

echo "Eclipse Che [login]..."
echo "Performing auth:Login..."
chectl auth:login -u admin -p admin --chenamespace=eclipse-che
