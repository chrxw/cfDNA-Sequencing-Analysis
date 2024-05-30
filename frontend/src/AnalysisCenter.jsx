import React from 'react';
import { Link } from 'react-router-dom';
import styled from 'styled-components';
import { Button } from 'antd';
import dnatest from './assets/dna-test.png';
import qualitycontrol from './assets/quality-control.png';
import molecular from './assets/molecular.png';
import sortdescending from './assets/sort-descending.png';
import duplicate from './assets/duplicate.png';
import menu from './assets/menu.png';
import dna from './assets/dna.png';

// Styled component for the topic
const StyledTopic = styled.div`
    font-family: 'Dongle', sans-serif;
    color: ${({ color }) => color || '#094067'};
    font-weight: 400; /* Add font weight */
`;

// Styled component for the tool container
const ToolContainer = styled.div`
    display: flex;
    flex-direction: column; /* Stack image and name vertically */
    align-items: flex-start; /* Align items to the start */
    margin-bottom: 20px;
`;

// Styled component for the tool image
const ToolImage = styled.img`
    width: 50px; /* Adjust as needed */
    height: 50px; /* Adjust as needed */
    margin-right: 10px; /* Add margin to the right of the image */
`;

// Styled component for the title
const Title = styled.h2`
    font-size: 50px;
    font-weight: 400; /* Add font weight */
    margin-bottom: 10px;
`;

// Styled component for the button text
const ButtonText = styled.p`
    font-size: 35px;
    font-weight: 400;
    margin: 0; /* Remove default margin */
    margin-left: 10px; /* Adjust margin to create space between image and text */
`;

// Styled component for the button
const StyledButton = styled(Button)`
    width: 380px;
    height: 91px;
    padding: 15px 30px; /* Adjust padding as needed */
    background-color: #3DA9FC; /* Button background color */
    border-color: #3DA9FC; /* Button border color */
    display: flex;
    align-items: center;
    margin-bottom: 20px;
    margin-top: 10px;
    
    // Adjust the hover color
    &:hover {
        background-color: rgba(61, 169, 252, 0.7) !important;
    }
`;

// Styled component for the button description
const ButtonDescription = styled.p`
    font-size: 25px;
    font-weight: 10;
    margin: 0; /* Remove default margin */
    margin-top: -15px; /* Add margin to create space between text and description */
    margin-left: 10px;
  
`;
// Styled component for the button text and description wrapper
const ButtonTextWrapper = styled.div`
    display: flex;
    flex-direction: column;
    align-items: flex-start;
`;

function AnalysisCenter() {
    return (
        <div style={{ padding: 40 }}>
            <StyledTopic color="#094067">
                <Title>Core Tools</Title>
                {/* Core tools */}
                <ToolContainer>
                    {/* Use Link instead of a regular button */}
                    <Link to="/CancerPrediction">
                        <StyledButton type="primary">
                            <ToolImage src={dnatest} alt="DNA Test" />
                            <ButtonTextWrapper>
                                <ButtonText>Cancer Prediction</ButtonText>
                                <ButtonDescription>cfDNA Sequencing Analysis</ButtonDescription>
                            </ButtonTextWrapper>
                        </StyledButton>
                    </Link>
                </ToolContainer>
            </StyledTopic>

            <StyledTopic color="#094067">
                <Title>Analysis Tools</Title>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 480px)', columnGap: '2px', rowGap: '2px' }}>
                    {/* Analysis tools */}
                    <ToolContainer>
                    <Link to="/QualityControl">
                        <StyledButton type="primary">
                            <ToolImage src={qualitycontrol} alt="Quality Control" />
                            <ButtonTextWrapper>
                                <ButtonText>Quality Control</ButtonText>
                                <ButtonDescription>FastQC</ButtonDescription>
                            </ButtonTextWrapper>
                        </StyledButton>
                        </Link>
                    </ToolContainer>
                    <ToolContainer>
                    <Link to="/Mapping">
                        <StyledButton type="primary">
                            <ToolImage src={molecular} alt="Molecular" />
                            <ButtonTextWrapper>
                                <ButtonText>Mapping</ButtonText>
                                <ButtonDescription>Bwa-mem</ButtonDescription>
                            </ButtonTextWrapper>
                        </StyledButton>
                        </Link>
                    </ToolContainer>
                    <ToolContainer>
                    <Link to="/Sorting">
                        <StyledButton type="primary">
                            <ToolImage src={sortdescending} alt="Sort Descending" />
                            <ButtonTextWrapper>
                                <ButtonText>Sorting</ButtonText>
                                <ButtonDescription>SamTools</ButtonDescription>
                            </ButtonTextWrapper>
                        </StyledButton>
                        </Link>
                    </ToolContainer>
                    <ToolContainer>
                    <Link to="/MarkDuplicates">
                        <StyledButton type="primary">
                            <ToolImage src={duplicate} alt="Duplicate" />
                            <ButtonTextWrapper>
                                <ButtonText>MarkDuplicates</ButtonText>
                                <ButtonDescription>Picard</ButtonDescription>
                            </ButtonTextWrapper>
                        </StyledButton>
                        </Link>
                    </ToolContainer>
                    <ToolContainer>
                    <Link to="/Indexing">
                        <StyledButton type="primary">
                            <ToolImage src={menu} alt="Menu" />
                            <ButtonTextWrapper>
                                <ButtonText>Indexing</ButtonText>
                                <ButtonDescription>SamTools</ButtonDescription>
                            </ButtonTextWrapper>
                        </StyledButton>
                        </Link>
                    </ToolContainer>
                    <ToolContainer>
                    <Link to="/CNVCalling">
                        <StyledButton type="primary">
                            <ToolImage src={dna} alt="DNA" />
                            <ButtonTextWrapper>
                                <ButtonText>CNV Calling</ButtonText>
                                <ButtonDescription>ichorCNA</ButtonDescription>
                            </ButtonTextWrapper>
                        </StyledButton>
                        </Link>
                    </ToolContainer>
                </div>
            </StyledTopic>
        </div>
    );
}

export default AnalysisCenter;
