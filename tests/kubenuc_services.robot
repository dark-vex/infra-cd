*** Settings ***
Documentation     Test suite per verificare la raggiungibilità dei servizi kubenuc-test
Library           RequestsLibrary
Library           Collections

*** Variables ***
${BASE_DOMAIN}              tst.ddlns.net
${TIMEOUT}                  30
${VERIFY_SSL}               ${FALSE}

# Service URLs
${HARBOR_URL}               https://harbor.${BASE_DOMAIN}
${JENKINS_URL}              https://jenkins.${BASE_DOMAIN}
${ARTIFACTORY_URL}          https://artifactory.${BASE_DOMAIN}
${NEXTCLOUD_URL}            https://cloud.${BASE_DOMAIN}
${PORTAINER_URL}            https://portainer.${BASE_DOMAIN}
${JELLYFIN_URL}             https://tv.${BASE_DOMAIN}
${SSO_URL}                  https://sso.${BASE_DOMAIN}
${S3_API_URL}               https://s3-api.${BASE_DOMAIN}
${S3_WEB_URL}               https://nx.s3.${BASE_DOMAIN}

*** Test Cases ***
Harbor Is Reachable
    [Documentation]    Verifica che Harbor sia raggiungibile
    [Tags]    harbor    critical
    Verify Service Responds    ${HARBOR_URL}    Harbor

Jenkins Is Reachable
    [Documentation]    Verifica che Jenkins sia raggiungibile
    [Tags]    jenkins    critical
    Verify Service Responds    ${JENKINS_URL}    Jenkins

Artifactory Is Reachable
    [Documentation]    Verifica che Artifactory sia raggiungibile
    [Tags]    artifactory    critical
    Verify Service Responds    ${ARTIFACTORY_URL}    Artifactory

Nextcloud Is Reachable
    [Documentation]    Verifica che Nextcloud sia raggiungibile
    [Tags]    nextcloud    critical
    Verify Service Responds    ${NEXTCLOUD_URL}    Nextcloud

Portainer Is Reachable
    [Documentation]    Verifica che Portainer sia raggiungibile
    [Tags]    portainer    critical
    Verify Service Responds    ${PORTAINER_URL}    Portainer

Jellyfin Is Reachable
    [Documentation]    Verifica che Jellyfin sia raggiungibile
    [Tags]    jellyfin    critical
    Verify Service Responds    ${JELLYFIN_URL}    Jellyfin

SSO Authentik Is Reachable
    [Documentation]    Verifica che Authentik SSO sia raggiungibile
    [Tags]    sso    critical
    Verify Service Responds    ${SSO_URL}    SSO

S3 API Is Reachable
    [Documentation]    Verifica che l'API S3 Garage sia raggiungibile
    [Tags]    s3    critical
    Verify Service Responds    ${S3_API_URL}    S3 API

S3 Web Is Reachable
    [Documentation]    Verifica che l'interfaccia web S3 sia raggiungibile
    [Tags]    s3    critical
    Verify Service Responds    ${S3_WEB_URL}    S3 Web

*** Keywords ***
Verify Service Responds
    [Documentation]    Verifica che un servizio risponda (status < 500)
    [Arguments]    ${url}    ${service_name}
    ${response}=    GET    ${url}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Log    ${service_name} responded with status ${response.status_code}
    Should Be True    ${response.status_code} < 500    ${service_name} returned server error: ${response.status_code}
