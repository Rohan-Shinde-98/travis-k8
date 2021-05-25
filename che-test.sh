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
    read -ra sep <<< "$CHE_SERVER_CUSTOM_IMAGE"
    if [ ${#sep[@]} != 2 ]
    then
      echo "che server image needs to be in format: [server/]imageName:imageTag. Found ${CHE_SERVER_CUSTOM_IMAGE}"
      exit 1
    fi
    unset IFS
    echo "    cheImage: '${sep[0]}'"
    echo "    cheImageTag: ${sep[1]}"
    echo "    cheImagePullPolicy: IfNotPresent"
	fi
  )"

echo $str > .travis.yml

unset IFS
