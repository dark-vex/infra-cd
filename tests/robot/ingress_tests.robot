*** Settings ***
Documentation    Test that all Kubernetes ingresses return HTTP 200 and take screenshots
Library          RequestsLibrary
Library          Collections
Library          OperatingSystem
Library          String
Library          ingress_helper.py
Library          SeleniumLibrary

Suite Setup      Initialize Test Suite
Suite Teardown   Cleanup Test Suite

*** Variables ***
${TIMEOUT}              30
${VERIFY_SSL}           ${FALSE}
${EXPECTED_STATUS}      200
${SCREENSHOT_DIR}       ${CURDIR}/screenshots
${HEADLESS}             ${TRUE}

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
    Create Directory   ${SCREENSHOT_DIR}

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

    # Take screenshot of the ingress endpoint if status is successful
    Run Keyword If    '${response}' != 'None' and ${response.status_code} >= 200 and ${response.status_code} < 400
    ...    Take Ingress Screenshot    ${url}    ${name}

Take Ingress Screenshot
    [Documentation]    Take a screenshot of an ingress endpoint using Selenium
    [Arguments]        ${url}    ${name}
    ${options}=        Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Run Keyword If    ${HEADLESS}    Call Method    ${options}    add_argument    --headless
    Call Method        ${options}    add_argument    --no-sandbox
    Call Method        ${options}    add_argument    --disable-dev-shm-usage
    Call Method        ${options}    add_argument    --ignore-certificate-errors
    Call Method        ${options}    add_argument    --disable-gpu
    ${screenshot_path}=    Set Variable    ${SCREENSHOT_DIR}/${name}.png
    TRY
        Open Browser       ${url}    chrome    options=${options}
        Set Window Size    1920    1080
        Sleep              2s    # Wait for page to load
        Capture Page Screenshot    ${screenshot_path}
        Log To Console     Screenshot saved: ${screenshot_path}
    EXCEPT
        Log To Console     Failed to take screenshot for ${name}: ${url}
    FINALLY
        Close Browser
    END

Cleanup Test Suite
    [Documentation]    Cleanup after tests
    Log To Console     \n========================================
    Log To Console     Ingress HTTP validation completed
    Log To Console     Screenshots saved to: ${SCREENSHOT_DIR}
    Log To Console     ========================================
