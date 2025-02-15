#!/bin/bash

set -e

NEXUS_VERSION=$1
NEXUS_API_VERSION=$2
TOOL=$3

validate(){
    if [ -z "$TOOL" ]; then
        echo "No deliverable defined. Assuming that 'go run main.go' 
should be run."
        TOOL="go run main.go"
    fi

    if [ -z "$NEXUS_VERSION" ] || [ -z "$NEXUS_API_VERSION" ]; then
        echo "NEXUS_VERSION and NEXUS_API_VERSION should be specified."
        exit 1
    fi
}

nexus(){
    docker run -d -p 9999:8081 --name nexus sonatype/nexus3:${NEXUS_VERSION}
}

readiness(){
    until docker logs nexus | grep 'Started Sonatype Nexus OSS'
    do
        echo "Nexus unavailable"
        sleep 2
    done
}

artifacts(){
    echo "Testing upload..."
    $TOOL upload -u admin -r maven-releases -n http://localhost:9999 -v ${NEXUS_API_VERSION} -d
    echo
    echo "Testing backup..."
    $TOOL backup -n http://localhost:9999 -u admin -r maven-releases -v ${NEXUS_API_VERSION}
    echo
    echo "Testing repositories..."
    $TOOL repositories -n http://localhost:9999 -u admin -v ${NEXUS_API_VERSION} -b
}

cleanup(){
    docker stop nexus
    docker rm nexus
}

main(){
    validate
    nexus
    readiness
    artifacts
    cleanup
}

main
