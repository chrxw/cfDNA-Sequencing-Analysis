import React from 'react';
import styled from 'styled-components';

// Styled component for the topic
const StyledTopic = styled.div`
    font-family: 'Dongle', sans-serif;
    color: ${({ color }) => color || '#094067'};
    font-weight: 400; /* Add font weight */
`;

// Styled component for the title
const Title = styled.h2`
    font-size: 50px;
    font-weight: 400; /* Add font weight */
    margin-bottom: 20px;
`;

// Styled component for the container of each box and label
const BoxContainer = styled.div`
    display: flex;
    flex-direction: column; /* Adjust to column layout */
    align-items: flex-start;
    margin-bottom: 20px;
    margin-left: 30px;
`;


// Styled component for the label
const Label = styled.div`
    font-size: 25px;
    font-weight: bold;
    margin-bottom: 10px;
    color: #5F6C7B;
    font-family: Dongle;
    font-weight: 400;
    word-wrap: break-word;
`;

// Styled component for the fill box
const FillBox = styled.div`
    width: 806px;
    height: 39px;
    border-radius: 10px;
    border: 1px solid #094067;
`;

function CancerPredictionPage() {
    return (
        <div style={{ padding: 40 }}>
            <StyledTopic color="#094067">
                <Title>Cancer Prediction</Title>
            </StyledTopic>
            {/* Box 1: Workflow name */}
            <BoxContainer>
                <Label>Workflow name</Label>
                <FillBox />
            </BoxContainer>
            {/* Box 2: Sample name */}
            <BoxContainer>
                <Label>Sample name</Label>
                <FillBox />
            </BoxContainer>
            {/* Box 3: Select first set of reads */}
            <BoxContainer>
                <Label>Select first set of reads</Label>
                <FillBox />
            </BoxContainer>
            {/* Box 4: Select second set of reads */}
            <BoxContainer>
                <Label>Select second set of reads</Label>
                <FillBox />
            </BoxContainer>
            {/* Box 5: Sample type */}
            <BoxContainer>
                <Label>Sample type</Label>
                <FillBox />
            </BoxContainer>
            {/* Box 6: Diagnosis group */}
            <BoxContainer>
                <Label>Diagnosis group</Label>
                <FillBox />
            </BoxContainer>
            {/* Box 7: Entity type */}
            <BoxContainer>
                <Label>Entity type</Label>
                <FillBox />
            </BoxContainer>
        </div>
    );
}

export default CancerPredictionPage;
