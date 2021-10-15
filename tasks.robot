*** Settings ***
Documentation   This Robot will get the order files from the intranet
...             Read the robot orders and place them on the intranet website
...             Saves the order html receipt as a PDF File
...             Saves the ordered robot screenshot.
...             Embeds the screenshot of the robot in the pdf recipt
...             creates a zip file of the receipts and images
Library     RPA.HTTP
Library     RPA.PDF
Library     RPA.Browser.Selenium
Library     RPA.Tables
Library     RPA.FileSystem
Library     RPA.Archive
Library     RPA.Dialogs
Library     RPA.Robocorp.Vault
Library     RPA.RobotLogListener


*** Variables ***
${orderfolder}=    output${/}orders
${filetemplate}   
${GLOBAL_RETRY_AMOUNT}=    5x
${GLOBAL_RETRY_INTERVAL}=    0.2s

*** Keyword ***
Open Intranet Website
    ${secret}=    Get Secret    processdata
    Open Available Browser      ${secret}[url]

*** Keyword ***
Get Orders
    Download        https://robotsparebinindustries.com/orders.csv  overwrite=True
    ${orders}=      Read Table From CSV     orders.csv      header=True
    [Return]        ${orders}

*** Keyword ***
Close Popup
    Wait Until Element Is Visible   class:btn.btn-dark
    Click Button    class:btn.btn-dark

*** Keyword ***
Fill The Form
    [Arguments]     ${order}
    Select From List By Value       id:head     ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text      class:form-control          ${order}[Legs]
    Input Text      id:address                  ${order}[Address]

*** Keyword ***
Preview The Robot
    Click Button    Class:btn.btn-secondary

*** Keyword ***
Try to Order
    Click Button    id:order
    Wait Until Element Is Visible     id:order-completion

*** Keyword ***
Submit The Order
    Mute Run On Failure     Try to Order
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Try to Order

*** Keyword ***
Store The Receipt As PDF File
    [Arguments]     ${ordernum}
    Wait Until Element Is Visible     id:order-completion
    ${receipt_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf     ${receipt_html}     ${CURDIR}${/}${orderfolder}${/}${filetemplate}_${ordernum}.pdf
    [Return]    ${CURDIR}${/}${orderfolder}${/}${filetemplate}_${ordernum}.pdf

*** Keyword ***
Take Screenshot Of The Robot
    [Arguments]     ${ordernum}
    Wait Until Element Is Visible     id:robot-preview-image
    Screenshot      id:robot-preview-image      ${CURDIR}${/}${orderfolder}${/}robot_preview_${ordernum}.png
    [Return]    ${CURDIR}${/}${orderfolder}${/}robot_preview_${ordernum}.png

*** Keyword ***
Embed Screenshot In PDF
    [Arguments]     ${screenshot}   ${pdf}  ${ordernum}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    image_path=${screenshot}    output_path=${pdf}
    Close Pdf   ${pdf}

*** Keyword ***
Go to Order Another Robot
    Click Button    id:order-another
    Wait Until Element Is Visible   class:btn.btn-dark

*** Keyword ***
Create Zipfile Of PDF And Screenshot
    Archive Folder With Zip     ${CURDIR}${/}${orderfolder}     ${CURDIR}${/}output${/}orders.zip

*** Keywords ***
Clean Up Work
    Close Browser

*** Keywords ***
Ask for User Data     
    Add heading       Please Input File Template Name
    Add text input    fln    label=FileTemplateName
    ${tempvar}=   Run Dialog
    log     ${tempvar}
    Set Global Variable    ${filetemplate}  ${tempvar}[fln]

*** Tasks ***
Tasks to complete the placing of orders and capture of information
    Ask for User Data
    Open Intranet Website
    ${orders}=  Get Orders
    FOR     ${order}    IN     @{orders}
        Close Popup
        Fill The Form       ${order}
        Preview The Robot
        Submit The Order
        ${pdf}=     Store The Receipt As PDF File       ${order}[Order number]
        ${screenshot}=      Take Screenshot Of The Robot    ${order}[Order number]
        Embed Screenshot In PDF     ${screenshot}   ${pdf}  ${order}[Order number]
        Go to Order Another Robot
    END
    Create Zipfile Of PDF And Screenshot
    Clean Up Work
    Log  Done...


