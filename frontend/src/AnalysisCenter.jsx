import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
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
    const navigate = useNavigate();

    const tools = [
        {
            tool_id: 'tl001',
            tool_name: 'Cancer Prediction',
            package_name: 'cfDNA Sequencing Analysis',
            img: dnatest,
            link: '/CancerPrediction'
        },
        {
            tool_id: 'tl002',
            tool_name: 'Quality Control',
            package_name: 'FastQC',
            img: qualitycontrol,
            link: '/QualityControl'
        },
        {
            tool_id: 'tl003',
            tool_name: 'Mapping',
            package_name: 'Bwa-mem',
            img: molecular,
            link: '/Mapping'
        },
        {
            tool_id: 'tl004',
            tool_name: 'Sorting',
            package_name: 'SamTools',
            img: sortdescending,
            link: '/Sorting'
        },
        {
            tool_id: 'tl005',
            tool_name: 'MarkDuplicates',
            package_name: 'Picard',
            img: duplicate,
            link: '/MarkDuplicates'
        },
        {
            tool_id: 'tl006',
            tool_name: 'Indexing',
            package_name: 'SamTools',
            img: menu,
            link: '/Indexing'
        },
        {
            tool_id: 'tl007',
            tool_name: 'CNV Calling',
            package_name: 'ichorCNA',
            img: dna,
            link: '/CNVCalling'
        }
    ];

    const handleToolClick = (tool) => {
        navigate(tool.link, { state: { tool_id: tool.tool_id } });
    };


    return (
        <div style={{ padding: 40 }}>
            <StyledTopic color="#094067">
                <Title>Core Tools</Title>
                {/* Core tools */}
                <ToolContainer>
                    <StyledButton type="primary" onClick={() => handleToolClick(tools[0])}>
                        <ToolImage src={tools[0].img} alt={tools[0].tool_name} />
                        <ButtonTextWrapper>
                            <ButtonText>{tools[0].tool_name}</ButtonText>
                            <ButtonDescription>{tools[0].package_name}</ButtonDescription>
                        </ButtonTextWrapper>
                    </StyledButton>
                </ToolContainer>
            </StyledTopic>

            <StyledTopic color="#094067">
                <Title>Analysis Tools</Title>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 480px)', columnGap: '2px', rowGap: '2px' }}>
                    {tools.slice(1).map((tool) => (
                        <ToolContainer key={tool.tool_id}>
                            <StyledButton type="primary" onClick={() => handleToolClick(tool)}>
                                <ToolImage src={tool.img} alt={tool.tool_name} />
                                <ButtonTextWrapper>
                                    <ButtonText>{tool.tool_name}</ButtonText>
                                    <ButtonDescription>{tool.package_name}</ButtonDescription>
                                </ButtonTextWrapper>
                            </StyledButton>
                        </ToolContainer>
                    ))}
                </div>
            </StyledTopic>
        </div>
    );
}

export default AnalysisCenter;
