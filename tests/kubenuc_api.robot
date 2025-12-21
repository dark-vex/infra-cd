*** Settings ***
Documentation     Test suite per verificare le API dei servizi kubenuc-test
Library           RequestsLibrary
Library           JSONLibrary
Library           Collections

Suite Setup       Create API Session

*** Variables ***
${BASE_DOMAIN}              tst.ddlns.net
${TIMEOUT}                  30
${VERIFY_SSL}               ${FALSE}

# Service URLs
${HARBOR_URL}               https://harbor.${BASE_DOMAIN}
${NEXTCLOUD_URL}            https://cloud.${BASE_DOMAIN}
${PORTAINER_URL}            https://portainer.${BASE_DOMAIN}
${JELLYFIN_URL}             https://tv.${BASE_DOMAIN}
${SSO_URL}                  https://sso.${BASE_DOMAIN}

*** Test Cases ***
Harbor Health API Returns Valid JSON
    [Documentation]    Verifica che l'API health di Harbor restituisca JSON valido
    [Tags]    harbor    api    json
    ${response}=    GET    ${HARBOR_URL}/api/v2.0/health    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Run Keyword If    ${response.status_code} == 200    Validate Harbor Health Response    ${response}

Harbor System Info API Is Available
    [Documentation]    Verifica l'endpoint systeminfo di Harbor
    [Tags]    harbor    api
    ${response}=    GET    ${HARBOR_URL}/api/v2.0/systeminfo    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Harbor systeminfo API error: ${response.status_code}

Nextcloud Status Returns Valid JSON
    [Documentation]    Verifica che lo status di Nextcloud restituisca JSON valido
    [Tags]    nextcloud    api    json
    ${response}=    GET    ${NEXTCLOUD_URL}/status.php    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Run Keyword If    ${response.status_code} == 200    Validate Nextcloud Status Response    ${response}

Nextcloud Capabilities API
    [Documentation]    Verifica l'endpoint capabilities di Nextcloud
    [Tags]    nextcloud    api
    ${response}=    GET    ${NEXTCLOUD_URL}/ocs/v1.php/cloud/capabilities    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Nextcloud capabilities API error: ${response.status_code}

Portainer API Status Returns Valid JSON
    [Documentation]    Verifica che l'API status di Portainer restituisca JSON valido
    [Tags]    portainer    api    json
    ${response}=    GET    ${PORTAINER_URL}/api/status    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Run Keyword If    ${response.status_code} == 200    Validate JSON Response    ${response}

Portainer Settings API
    [Documentation]    Verifica l'endpoint settings di Portainer (pubblico)
    [Tags]    portainer    api
    ${response}=    GET    ${PORTAINER_URL}/api/settings/public    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Portainer settings API error: ${response.status_code}

Jellyfin System Info API
    [Documentation]    Verifica l'endpoint system info di Jellyfin
    [Tags]    jellyfin    api
    ${response}=    GET    ${JELLYFIN_URL}/System/Info/Public    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Run Keyword If    ${response.status_code} == 200    Validate Jellyfin Info Response    ${response}

Jellyfin Branding API
    [Documentation]    Verifica l'endpoint branding di Jellyfin
    [Tags]    jellyfin    api
    ${response}=    GET    ${JELLYFIN_URL}/Branding/Configuration    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    Jellyfin branding API error: ${response.status_code}

SSO Health Live Check
    [Documentation]    Verifica l'endpoint health live di Authentik
    [Tags]    sso    api    health
    ${response}=    GET    ${SSO_URL}/-/health/live/    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    SSO health live check failed: ${response.status_code}

SSO Health Ready Check
    [Documentation]    Verifica l'endpoint health ready di Authentik
    [Tags]    sso    api    health
    ${response}=    GET    ${SSO_URL}/-/health/ready/    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    Should Be True    ${response.status_code} < 500    SSO health ready check failed: ${response.status_code}

*** Keywords ***
Create API Session
    [Documentation]    Setup per i test API
    Set Library Search Order    RequestsLibrary
    Log    API test suite inizializzata per dominio: ${BASE_DOMAIN}

Validate JSON Response
    [Documentation]    Verifica che la risposta sia JSON valido
    [Arguments]    ${response}
    ${json}=    Convert String To Json    ${response.text}
    Should Not Be Empty    ${json}

Validate Harbor Health Response
    [Documentation]    Valida la struttura della risposta health di Harbor
    [Arguments]    ${response}
    ${json}=    Convert String To Json    ${response.text}
    Should Not Be Empty    ${json}
    Log    Harbor health response: ${json}

Validate Nextcloud Status Response
    [Documentation]    Valida la struttura della risposta status di Nextcloud
    [Arguments]    ${response}
    ${json}=    Convert String To Json    ${response.text}
    Should Not Be Empty    ${json}
    # Nextcloud status dovrebbe contenere 'installed' e 'version'
    ${installed}=    Get Value From Json    ${json}    $.installed
    ${version}=    Get Value From Json    ${json}    $.version
    Log    Nextcloud installed: ${installed}, version: ${version}

Validate Jellyfin Info Response
    [Documentation]    Valida la struttura della risposta info di Jellyfin
    [Arguments]    ${response}
    ${json}=    Convert String To Json    ${response.text}
    Should Not Be Empty    ${json}
    # Jellyfin info dovrebbe contenere 'ServerName' e 'Version'
    ${server_name}=    Get Value From Json    ${json}    $.ServerName
    ${version}=    Get Value From Json    ${json}    $.Version
    Log    Jellyfin server: ${server_name}, version: ${version}
