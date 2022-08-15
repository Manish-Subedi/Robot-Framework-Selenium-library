*** Settings ***
Documentation       Car dealer Assignment 10
...                 Manish Subedi
...
Library             SeleniumLibrary         run_on_failure=nothing
Library             Dialogs
Library             Process
Library             Screenshot
Library             FakerLibrary    fi_FI
Library             String

Test Setup          Start Container
Test Teardown       Stop Container


*** Variables ***
${LOGIN URL}      http://localhost:3000
${BROWSER}        Chrome
${count}         0
${numberOfDeletedPlate}     0
${plateToDelete}    ABC-123
${carToDelete}    Skoda
@{Cars}       Toyota     Skoda      Audi

*** Test Cases ***
Test_One
    Open Browser To Login Page
    Manual add    BMW     X6     15000       2020      ABC-123
    Delay
    Auto add   2
    Screenshot     initital-screenshot-1.png
    Delete Using number plate
    Screenshot     final-screenshot-1.png

Test_Two
    Open Browser To Login Page
    Auto add   10
    Capture Page Screenshot     initital-screenshot-2.png
    Remove and check car
    Capture Page Screenshot     final-screenshot-2.png


*** Keywords ***
Start Container
    Log     Starting container
    Run Process     docker-compose    up    --detach

Stop Container
    Pause Execution
    Close Browser
    Run Process     docker-compose    down

Open Browser To Login Page
    Open Browser    ${LOGIN URL}    ${BROWSER}
    Title Should Be    Car store

LicensePlate
    ${Start}      Generate Random String     length= 3    chars= [UPPER]
    ${End}        Generate Random String     length= 3    chars= [NUMBERS]
    ${plate}      Catenate    SEPARATOR=-   ${Start}   ${End}
    [Return]      ${plate}

Manual add
    [Arguments]         ${carname}         ${carmodel}        ${carmileage}      ${year}     ${carplate}
    Click Element     xpath://a[@href="/add"]
    Title Should Be     Add a new car
    Input Text          make-input          ${carname}
    Input Text          model-input         ${carmodel}
    Input Text          mileage-input       ${carmileage}
    Input Text          year-input          ${year}
    Input Text          plate-input         ${carplate}
    Click Button        Add a new car

Auto add
    [Arguments]         ${number_of_car}
      FOR    ${x}    IN RANGE    ${number_of_car}
        ${carnamea}=      Evaluate  random.choice($Cars)  random
        ${platenumber}    LicensePlate
        ${mileage}        FakerLibrary.Random Number
        ${model}          Generate Random String     length= 2    chars= [UPPER]
        ${year}           FakerLibrary.Year
        Manual add     ${car_namea}      ${model}     ${mileage}    ${year}     ${platenumber}
        Delay
      END

Delay
    Wait Until Page Contains Element        xpath=//div[@id="car-container"]

Delete Using number plate
      ${elementCount}    Get Element Count  //*[@id="car-container"]/a
    FOR    ${i}    IN RANGE    0    ${elementCount}
        ${count}=        Evaluate            ${count}+1
        Log        ${count}
        ${text}=        Get Text       //*[@id="car-container"]/a[${count}]/div/div[5]/span[2]
        ${foundPlate}=  Run Keyword And Return Status   Should Be Equal As Strings    ${text}    ${plateToDelete}
        IF  ${foundPlate}
           Right Click  ${count}
            ${count}=        Evaluate            ${count}-1
            ${numberOfDeletedPlate}     Evaluate        ${numberOfDeletedPlate}+1
        END
    END

    ${lengthAfterDeletion}=         Evaluate        ${elementCount}-${numberOfDeletedPlate}
    Check For plate     ${lengthAfterDeletion}

Right Click
    [Arguments]         ${count}
    Open Context Menu        //*[@id="car-container"]/a[${count}]/div/div[5]/span[2]
    Handle Alert    Accept      timeout=0.5s

Check For plate
    [Arguments]         ${plateLength}
    FOR    ${i}    IN RANGE    0    ${plateLength}
        ${count}=       Evaluate        ${i}+1
        ${text}=        Get Text       //*[@id="car-container"]/a[${count}]/div/div[5]/span[2]
        Should Not Be Equal     ${text}     ${plateToDelete}
    END


Remove Car From Page Using Car Name
    [Arguments]         ${name_of_the_car}
        FOR    ${x}    IN RANGE    10
            ${state2}=  Run Keyword And Return Status   Element Should Contain    xpath=//*[@id="car-container"]/a[${x}]/div/div[1]     ${name_of_the_car}
            Exit For Loop If    ${state2}
        END
        Open Context Menu    xpath=//*[@id="car-container"]/a[${x}]/div/div[1]
        Handle Alert    Accept      timeout=0.5s
        Delay


Check Car Exist In the Page
    [Arguments]         ${remove_data}
    ${remove_state}=  Run Keyword And Return Status   Element Should Contain    xpath=//*[@id="car-container"]   ${remove_data}
    [Return]       ${remove_state}


Remove and check car
    ${state} =    Check Car Exist In the Page    ${carToDelete}
    FOR    ${x}    IN RANGE    10
        Run Keyword If  ${state}   Remove Car From Page Using Car Name    ${carToDelete}
        sleep  2s
        ${state} =    Check Car Exist In the Page    ${carToDelete}
        Exit For Loop If   ${state} == ${false}
    END

Screenshot
    [Arguments]     ${filename}
    Capture Page Screenshot       ${filename}
