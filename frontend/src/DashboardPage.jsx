// DashboardPage.jsx
import React from 'react';
import styled from 'styled-components';

// Styled component for the container to center the content
const Container = styled.div`
    width: 100%;
    height: 100vh; /* Full height of the viewport */
    padding: 20px; /* Add some padding */
    box-sizing: border-box; /* Include padding in the element's total width and height */
    display: flex;
    align-items: flex-start; /* Align items to the top */
    // justify-content: space-between; /* Space out children */
    `;

// Styled component for the main message text
const MessageText = styled.div`
        color: #5F6C7B;
        font-size: 50px;
        font-family: Dongle;
        font-weight: 400;
        word-wrap: break-word;
        margin-top: 350px;
       margin-left: 620px;
    `;

// Styled component for the additional message text
const AdditionalMessageText = styled.div`
        color: #5F6C7B;
        font-size: 35px;
        font-family: Dongle;
        font-weight: 300;
        word-wrap: break-word;
        margin-top: 20px; /* Add some space between the two messages */
        margin-left: 430px;
     
    `;
function DashboardPage() {
    return (
        <Container>
            <div>
                <MessageText>This page is empty.</MessageText>
                <AdditionalMessageText>
                    You can load your own data or get data from an external source.
                </AdditionalMessageText>
            </div>
        </Container>
    );
}


export default DashboardPage;
// forhistory when no data