#!/bin/bash
# Set up the pipeline by creating the job configuration
# This assumes Jenkins CLI is configured and Jenkins is accessible

JENKINS_URL="http://localhost:8080"
JOB_NAME="Kubernetes_CI_CD_Pipeline"

curl -X POST "${JENKINS_URL}/createItem?name=${JOB_NAME}" --data @jenkins-job-config.xml -H "Content-Type: application/xml"
