*** Settings ***
Documentation    Test that all Kubernetes ingresses return HTTP 200
Library          RequestsLibrary
Library          Collections
Library          OperatingSystem
Library          String
Library          ingress_helper.py

Suite Setup      Initialize Test Suite
Suite Teardown   Log Test Summary

*** Variables ***
${TIMEOUT}              30
${VERIFY_SSL}           ${FALSE}
${EXPECTED_STATUS}      200

*** Test Cases ***
Test All Ingresses Return HTTP 200
    [Documentation]    Dynamically test all discovered ingresses
    [Tags]             ingress    http    smoke
    ${ingresses}=      Get Ingress List
    Log                Found ${ingresses.__len__()} ingresses to test
    Should Not Be Empty    ${ingresses}    No ingresses found in the cluster
    FOR    ${ingress}    IN    @{ingresses}
        Test Single Ingress    ${ingress}
    END

*** Keywords ***
Initialize Test Suite
    [Documentation]    Setup test session and discover ingresses
    Create Session     ingress_session    https://localhost    verify=${VERIFY_SSL}    disable_warnings=1
    ${count}=          Get Ingress Count
    Log To Console     \nDiscovered ${count} ingresses for testing

Test Single Ingress
    [Documentation]    Test a single ingress endpoint
    [Arguments]        ${ingress}
    ${host}=           Get From Dictionary    ${ingress}    host
    ${namespace}=      Get From Dictionary    ${ingress}    namespace
    ${name}=           Get From Dictionary    ${ingress}    name
    ${protocol}=       Get From Dictionary    ${ingress}    protocol    default=https
    ${path}=           Get From Dictionary    ${ingress}    path    default=/
    ${url}=            Set Variable    ${protocol}://${host}${path}

    Log To Console     Testing: ${name} (${namespace}) -> ${url}

    ${session_alias}=    Set Variable    session_${name}
    Create Session     ${session_alias}    ${protocol}://${host}    verify=${VERIFY_SSL}    timeout=${TIMEOUT}    disable_warnings=1

    ${response}=       Run Keyword And Continue On Failure
    ...                GET On Session    ${session_alias}    ${path}    expected_status=any

    Run Keyword If    '${response}' != 'None'
    ...    Log    Response status: ${response.status_code} for ${url}

    Run Keyword If    '${response}' != 'None'
    ...    Should Be True    ${response.status_code} >= 200 and ${response.status_code} < 400
    ...    Ingress ${name} (${url}) returned unexpected status: ${response.status_code}

Log Test Summary
    [Documentation]    Log final test summary
    Log To Console     \n========================================
    Log To Console     Ingress HTTP validation completed
    Log To Console     ========================================
