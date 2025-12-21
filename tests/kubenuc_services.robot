*** Settings ***
Documentation     Test suite per verificare la raggiungibilità dei servizi kubenuc-test
Library           RequestsLibrary
Library           Collections

Suite Setup       Create Test Session

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
Harbor Container Registry Is Reachable
    [Documentation]    Verifica che Harbor sia raggiungibile
    [Tags]    harbor    registry    critical
    ${response}=    GET    ${HARBOR_URL}/api/v2.0/health    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Harbor returned server error: ${response.status_code}
    Log    Harbor status: ${response.status_code}

Harbor API Version Endpoint
    [Documentation]    Verifica l'endpoint API version di Harbor
    [Tags]    harbor    api
    ${response}=    GET    ${HARBOR_URL}/api/version    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Harbor API returned error: ${response.status_code}

Jenkins CI Is Reachable
    [Documentation]    Verifica che Jenkins sia raggiungibile
    [Tags]    jenkins    ci    critical
    ${response}=    GET    ${JENKINS_URL}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Jenkins returned server error: ${response.status_code}
    Log    Jenkins status: ${response.status_code}

Jenkins Login Page Available
    [Documentation]    Verifica che la pagina di login Jenkins sia disponibile
    [Tags]    jenkins    login
    ${response}=    GET    ${JENKINS_URL}/login    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Jenkins login page error: ${response.status_code}

Artifactory Is Reachable
    [Documentation]    Verifica che Artifactory (JFrog ACR) sia raggiungibile
    [Tags]    artifactory    registry    critical
    ${response}=    GET    ${ARTIFACTORY_URL}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Artifactory returned server error: ${response.status_code}
    Log    Artifactory status: ${response.status_code}

Artifactory Health Check
    [Documentation]    Verifica lo stato di salute di Artifactory
    [Tags]    artifactory    health
    ${response}=    GET    ${ARTIFACTORY_URL}/artifactory/api/system/ping    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Artifactory health check failed: ${response.status_code}

Nextcloud Is Reachable
    [Documentation]    Verifica che Nextcloud sia raggiungibile
    [Tags]    nextcloud    cloud    critical
    ${response}=    GET    ${NEXTCLOUD_URL}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Nextcloud returned server error: ${response.status_code}
    Log    Nextcloud status: ${response.status_code}

Nextcloud Status Endpoint
    [Documentation]    Verifica l'endpoint status di Nextcloud
    [Tags]    nextcloud    status
    ${response}=    GET    ${NEXTCLOUD_URL}/status.php    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Nextcloud status endpoint error: ${response.status_code}

Portainer Is Reachable
    [Documentation]    Verifica che Portainer sia raggiungibile
    [Tags]    portainer    management    critical
    ${response}=    GET    ${PORTAINER_URL}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Portainer returned server error: ${response.status_code}
    Log    Portainer status: ${response.status_code}

Portainer API Status
    [Documentation]    Verifica l'API status di Portainer
    [Tags]    portainer    api
    ${response}=    GET    ${PORTAINER_URL}/api/status    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Portainer API error: ${response.status_code}

Jellyfin Media Server Is Reachable
    [Documentation]    Verifica che Jellyfin sia raggiungibile
    [Tags]    jellyfin    media    critical
    ${response}=    GET    ${JELLYFIN_URL}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Jellyfin returned server error: ${response.status_code}
    Log    Jellyfin status: ${response.status_code}

Jellyfin Health Endpoint
    [Documentation]    Verifica l'endpoint health di Jellyfin
    [Tags]    jellyfin    health
    ${response}=    GET    ${JELLYFIN_URL}/health    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Jellyfin health check failed: ${response.status_code}

SSO Authentik Is Reachable
    [Documentation]    Verifica che Authentik SSO sia raggiungibile
    [Tags]    sso    authentik    critical
    ${response}=    GET    ${SSO_URL}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    SSO returned server error: ${response.status_code}
    Log    SSO status: ${response.status_code}

SSO Health Check
    [Documentation]    Verifica l'endpoint health di Authentik
    [Tags]    sso    health
    ${response}=    GET    ${SSO_URL}/-/health/live/    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    SSO health check failed: ${response.status_code}

S3 API Garage Is Reachable
    [Documentation]    Verifica che l'API S3 Garage sia raggiungibile
    [Tags]    s3    storage    critical
    ${response}=    GET    ${S3_API_URL}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    # S3 può restituire 403 senza credenziali, ma il servizio è comunque raggiungibile
    Should Be True    ${response.status_code} < 500    S3 API returned server error: ${response.status_code}
    Log    S3 API status: ${response.status_code}

S3 Web Interface Is Reachable
    [Documentation]    Verifica che l'interfaccia web S3 sia raggiungibile
    [Tags]    s3    web
    ${response}=    GET    ${S3_WEB_URL}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    S3 Web returned server error: ${response.status_code}
    Log    S3 Web status: ${response.status_code}

*** Keywords ***
Create Test Session
    [Documentation]    Crea una sessione di test con configurazione comune
    Set Library Search Order    RequestsLibrary
    Log    Test suite inizializzata per dominio: ${BASE_DOMAIN}

Verify Service Is Up
    [Documentation]    Keyword riutilizzabile per verificare che un servizio sia attivo
    [Arguments]    ${url}    ${service_name}
    ${response}=    GET    ${url}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    ${service_name} returned server error: ${response.status_code}
    RETURN    ${response}
