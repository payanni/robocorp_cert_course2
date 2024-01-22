*** Settings ***
Documentation     Template robot main suite.
...               Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Word.Application
Library    RPA.Archive

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Click OK on the popup message
    Download the order file
    Fill the form using the data from the Excel file
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order
Click OK on the popup message
    Click Element When Clickable    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait Until Element Is Visible    head

Download the order file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}

Fill the form using the data from the Excel file
    ${orders_csv}=    Read table from CSV    orders.csv    header=${True}
    FOR    ${row}    IN    @{orders_csv}
        Fill and submit the form for order    ${row}
        Wait Until Keyword Succeeds    30s    1s    Preview the robot
        Wait Until Keyword Succeeds    30s    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click order another robot
        Click OK on the popup message
    END

Preview the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:preview    2s

Submit the order
    Click Element    id:order
    Wait Until Element Is Visible    id:order-completion    2s

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_completion_html}=    Get Element Attribute    id:order-completion    innerHTML
    Html To Pdf    ${order_completion_html}    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${TEMP_DIR}${/}previews${/}robot_preview_${order_number}.png
    Open Pdf    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf
    ${files}=    Create List    ${TEMP_DIR}${/}previews${/}robot_preview_${order_number}.png
    Add Files To Pdf    ${files}    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf    append=True
    Close Pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    No Operation

Fill and submit the form for order
    [Arguments]    ${orders_csv}
    Select From List By Index    id:head    ${orders_csv}[Head]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders_csv}[Legs]
    Input Text    id:address    ${orders_csv}[Address]
    Run Keyword If    '${orders_csv}[Body]' == '6'    Click Element    id:id-body-6
    ...    ELSE IF    '${orders_csv}[Body]' == '5'    Click Element    id:id-body-5
    ...    ELSE IF    '${orders_csv}[Body]' == '4'    Click Element    id:id-body-4
    ...    ELSE IF    '${orders_csv}[Body]' == '3'    Click Element    id:id-body-3
    ...    ELSE IF    '${orders_csv}[Body]' == '2'    Click Element    id:id-body-2
    ...    ELSE    Click Element    id:id-body-1

Click order another robot
    Wait Until Element Is Visible    order-another
    Click Element When Clickable   order-another

Create a ZIP file of the receipts
    Archive Folder With ZIP    ${TEMP_DIR}${/}orders    ${OUTPUT_DIR}${/}orders.zip    recursive=False    include=order*.pdf
