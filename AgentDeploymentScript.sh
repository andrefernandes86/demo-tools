#!/bin/bash

ACTIVATIONURL='dsm://agents.workload.trend-us-1.cloudone.trendmicro.com:443/'
MANAGERURL='https://workload.trend-us-1.cloudone.trendmicro.com:443'
CURLOPTIONS='--silent --tlsv1.2'
linuxPlatform='';
isRPM='';

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo You are not running as the root user.  Please try again with root privileges.;
    logger -t You are not running as the root user.  Please try again with root privileges.;
    exit 1;
fi;

if ! type curl >/dev/null 2>&1; then
    echo "Please install CURL before running this script."
    logger -t Please install CURL before running this script
    exit 1
fi

curl -L $MANAGERURL/software/deploymentscript/platform/linuxdetectscriptv1/ -o /tmp/PlatformDetection $CURLOPTIONS --insecure

if [ -s /tmp/PlatformDetection ]; then
    . /tmp/PlatformDetection
else
    echo "Failed to download the agent installation support script."
    logger -t Failed to download the Deep Security Agent installation support script
    exit 1
fi

platform_detect
if [[ -z "${linuxPlatform}" ]] || [[ -z "${isRPM}" ]]; then
    echo Unsupported platform is detected
    logger -t Unsupported platform is detected
    exit 1
fi

echo Downloading agent package...
if [[ $isRPM == 1 ]]; then package='agent.rpm'
    else package='agent.deb'
fi
curl -H "Agent-Version-Control: on" -L $MANAGERURL/software/agent/${runningPlatform}${majorVersion}/${archType}/$package?tenantID=27052 -o /tmp/$package $CURLOPTIONS --insecure

echo Installing agent package...
rc=1
if [[ $isRPM == 1 && -s /tmp/agent.rpm ]]; then
    rpm -ihv /tmp/agent.rpm
    rc=$?
elif [[ -s /tmp/agent.deb ]]; then
    dpkg -i /tmp/agent.deb
    rc=$?
else
    echo Failed to download the agent package. Please make sure the package is imported in the Workload Security Manager
    logger -t Failed to download the agent package. Please make sure the package is imported in the Workload Security Manager
    exit 1
fi
if [[ ${rc} != 0 ]]; then
    echo Failed to install the agent package
    logger -t Failed to install the agent package
    exit 1
fi

echo Install the agent package successfully

sleep 15
/opt/ds_agent/dsa_control -r
/opt/ds_agent/dsa_control -a $ACTIVATIONURL "tenantID:85CA171C-7754-438E-13D2-4EC3B964A489" "token:3D2B646B-639E-AEC7-DD9F-A4D2EF467029" "policyid:16"
# /opt/ds_agent/dsa_control -a dsm://agents.workload.trend-us-1.cloudone.trendmicro.com:443/ "tenantID:85CA171C-7754-438E-13D2-4EC3B964A489" "token:3D2B646B-639E-AEC7-DD9F-A4D2EF467029" "policyid:16"