*** Settings ***
Documentation     Test suite per verificare performance e tempi di risposta dei servizi kubenuc-test
Library           RequestsLibrary
Library           Collections
Library           DateTime

Suite Setup       Create Performance Session

*** Variables ***
${BASE_DOMAIN}              tst.ddlns.net
${TIMEOUT}                  30
${VERIFY_SSL}               ${FALSE}
${MAX_RESPONSE_TIME}        10    # secondi

# Service URLs
${HARBOR_URL}               https://harbor.${BASE_DOMAIN}
${JENKINS_URL}              https://jenkins.${BASE_DOMAIN}
${ARTIFACTORY_URL}          https://artifactory.${BASE_DOMAIN}
${NEXTCLOUD_URL}            https://cloud.${BASE_DOMAIN}
${PORTAINER_URL}            https://portainer.${BASE_DOMAIN}
${JELLYFIN_URL}             https://tv.${BASE_DOMAIN}
${SSO_URL}                  https://sso.${BASE_DOMAIN}

*** Test Cases ***
Harbor Response Time Is Acceptable
    [Documentation]    Verifica che Harbor risponda entro ${MAX_RESPONSE_TIME} secondi
    [Tags]    harbor    performance
    ${elapsed}=    Measure Response Time    ${HARBOR_URL}/api/v2.0/health
    Should Be True    ${elapsed} < ${MAX_RESPONSE_TIME}    Harbor response time ${elapsed}s exceeds ${MAX_RESPONSE_TIME}s

Jenkins Response Time Is Acceptable
    [Documentation]    Verifica che Jenkins risponda entro ${MAX_RESPONSE_TIME} secondi
    [Tags]    jenkins    performance
    ${elapsed}=    Measure Response Time    ${JENKINS_URL}
    Should Be True    ${elapsed} < ${MAX_RESPONSE_TIME}    Jenkins response time ${elapsed}s exceeds ${MAX_RESPONSE_TIME}s

Artifactory Response Time Is Acceptable
    [Documentation]    Verifica che Artifactory risponda entro ${MAX_RESPONSE_TIME} secondi
    [Tags]    artifactory    performance
    ${elapsed}=    Measure Response Time    ${ARTIFACTORY_URL}
    Should Be True    ${elapsed} < ${MAX_RESPONSE_TIME}    Artifactory response time ${elapsed}s exceeds ${MAX_RESPONSE_TIME}s

Nextcloud Response Time Is Acceptable
    [Documentation]    Verifica che Nextcloud risponda entro ${MAX_RESPONSE_TIME} secondi
    [Tags]    nextcloud    performance
    ${elapsed}=    Measure Response Time    ${NEXTCLOUD_URL}/status.php
    Should Be True    ${elapsed} < ${MAX_RESPONSE_TIME}    Nextcloud response time ${elapsed}s exceeds ${MAX_RESPONSE_TIME}s

Portainer Response Time Is Acceptable
    [Documentation]    Verifica che Portainer risponda entro ${MAX_RESPONSE_TIME} secondi
    [Tags]    portainer    performance
    ${elapsed}=    Measure Response Time    ${PORTAINER_URL}
    Should Be True    ${elapsed} < ${MAX_RESPONSE_TIME}    Portainer response time ${elapsed}s exceeds ${MAX_RESPONSE_TIME}s

Jellyfin Response Time Is Acceptable
    [Documentation]    Verifica che Jellyfin risponda entro ${MAX_RESPONSE_TIME} secondi
    [Tags]    jellyfin    performance
    ${elapsed}=    Measure Response Time    ${JELLYFIN_URL}/health
    Should Be True    ${elapsed} < ${MAX_RESPONSE_TIME}    Jellyfin response time ${elapsed}s exceeds ${MAX_RESPONSE_TIME}s

SSO Response Time Is Acceptable
    [Documentation]    Verifica che SSO risponda entro ${MAX_RESPONSE_TIME} secondi
    [Tags]    sso    performance
    ${elapsed}=    Measure Response Time    ${SSO_URL}/-/health/live/
    Should Be True    ${elapsed} < ${MAX_RESPONSE_TIME}    SSO response time ${elapsed}s exceeds ${MAX_RESPONSE_TIME}s

All Critical Services Respond Within SLA
    [Documentation]    Test aggregato che verifica tutti i servizi critici
    [Tags]    critical    sla
    @{services}=    Create List
    ...    ${HARBOR_URL}/api/v2.0/health
    ...    ${JENKINS_URL}
    ...    ${NEXTCLOUD_URL}/status.php
    ...    ${PORTAINER_URL}
    ...    ${SSO_URL}/-/health/live/

    FOR    ${service_url}    IN    @{services}
        ${elapsed}=    Measure Response Time    ${service_url}
        Log    ${service_url} responded in ${elapsed}s
        Should Be True    ${elapsed} < ${MAX_RESPONSE_TIME}    ${service_url} exceeded SLA: ${elapsed}s
    END

*** Keywords ***
Create Performance Session
    [Documentation]    Setup per i test di performance
    Set Library Search Order    RequestsLibrary
    Log    Performance test suite inizializzata

Measure Response Time
    [Documentation]    Misura il tempo di risposta di un endpoint
    [Arguments]    ${url}
    ${start}=    Get Current Date    result_format=epoch
    ${response}=    GET    ${url}    expected_status=any    verify=${VERIFY_SSL}    timeout=${TIMEOUT}
    ${end}=    Get Current Date    result_format=epoch
    ${elapsed}=    Evaluate    ${end} - ${start}
    Log    ${url} responded in ${elapsed} seconds with status ${response.status_code}
    RETURN    ${elapsed}
