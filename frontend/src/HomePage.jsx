import React from 'react';
import styled from 'styled-components';
import Lowgrade from './assets/Lowgrade.png';
import Ependymoma from './assets/Ependymoma.png';
import Medulloblastoma from './assets/Medulloblastoma.png';
import Others from './assets/Others.png';
import Highgrade from './assets/Highgrade.png';
import Diffuseintrinsic from './assets/Diffuseintrinsic.png';
import Nonmalignant from './assets/Nonmalignant.png';
import Meningioma from './assets/Meningioma.png';
import Atypicalteratoid from './assets/Atypicalteratoid.png';

// Define styled components for the topic
const StyledTopicContainer = styled.div`
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    margin-top: 50px; /* Add margin between topic */
`;

const StyledTopic = styled.div`
    font-family: 'Dongle', sans-serif;
    color: #5F6C7B;
    // font-weight: 400;
`;

const StyledHeader = styled.h1`
    font-size: 50px;
    color: #094067;
    margin-top: 0px;
    font-weight: 700;
`;

const StyledParagraph = styled.p`
    font-size: 30px;
    margin-top: -8px;
`;

const ImageContainer = styled.div`
    display: flex;
    align-items: center;
`;

const Image = styled.img`
    max-width: 100%;
    height: auto;
`;

const ImageName = styled.p`
    margin-left: 10px;
`;

function Topic({ title, children }) {
    return (
        <StyledTopic>
            <StyledHeader>{title}</StyledHeader>
            <StyledParagraph>{children}</StyledParagraph>
        </StyledTopic>
    );
}

function HomePage({ headerName }) {
    return (
        <div style={{ paddingLeft: 40, paddingRight: 40, paddingBottom: 40 }}>
            <StyledHeader>{headerName}</StyledHeader>
            <StyledTopicContainer>
                <Topic title="cfDNA Sequencing Analysis">
                    INTEGRATING SNAKEMAKE WORKFLOW WITH ADVANCED FRAGMENTOMICS FEATURES FOR NEXT-GENERATION SEQUENCING ANALYSIS OF CELL-FREE DNA IDENTIFIES ACTIONABLE INSIGHTS
                </Topic>
            </StyledTopicContainer>
            <StyledTopicContainer>
                <Topic title="123 Sample">
                    Control 10 Samples<br />Positive 113 Samples
                </Topic>
                <StyledTopic>
                    <StyledHeader>9 Diagnosis Groups</StyledHeader>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', columnGap: '20px', rowGap: '20px' }}>
                        <ImageContainer>
                            <Image src={Lowgrade} alt="Lowgrade" />
                            <ImageName>Low-grade glioma</ImageName>
                        </ImageContainer>
                        <ImageContainer>
                            <Image src={Ependymoma} alt="Ependymoma" />
                            <ImageName>Ependymoma</ImageName>
                        </ImageContainer>
                        <ImageContainer>
                            <Image src={Medulloblastoma} alt="Medulloblastoma" />
                            <ImageName>Medulloblastoma</ImageName>
                        </ImageContainer>
                        <ImageContainer>
                            <Image src={Others} alt="Others" />
                            <ImageName>Others</ImageName>
                        </ImageContainer>
                        <ImageContainer>
                            <Image src={Highgrade} alt="Highgrade" />
                            <ImageName>High-grade glioma</ImageName>
                        </ImageContainer>
                        <ImageContainer>
                            <Image src={Diffuseintrinsic} alt="Diffuseintrinsic" />
                            <ImageName>Diffuse intrinsic pontine glioma</ImageName>
                        </ImageContainer>
                        <ImageContainer>
                            <Image src={Nonmalignant} alt="Nonmalignant" />
                            <ImageName>Non-malignant</ImageName>
                        </ImageContainer>
                        <ImageContainer>
                            <Image src={Meningioma} alt="Meningioma" />
                            <ImageName>Meningioma</ImageName>
                        </ImageContainer>
                        <ImageContainer>
                            <Image src={Atypicalteratoid} alt="Atypicalteratoid" />
                            <ImageName>Atypical teratoid rhabdoid tumor</ImageName>
                        </ImageContainer>
                    </div>
                </StyledTopic>
            </StyledTopicContainer>
            <StyledTopicContainer>
                <Topic title="5 Tumor Entities">
                Brain cancer<br />Sarcoma cancer<br />Neuroblastoma<br />Hematolgical malignancies<br />other
                </Topic>
            </StyledTopicContainer>
        </div>
    );
}

export default HomePage;
