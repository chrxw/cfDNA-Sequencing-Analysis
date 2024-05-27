import React, { useEffect, useState } from 'react';
import styled from 'styled-components';
import axios from 'axios';

// image imports
import Lowgrade from './assets/Lowgrade.png';
import Ependymoma from './assets/Ependymoma.png';
import Medulloblastoma from './assets/Medulloblastoma.png';
import Others from './assets/Others.png';
import Highgrade from './assets/Highgrade.png';
import Diffuseintrinsic from './assets/Diffuseintrinsic.png';
import Nonmalignant from './assets/Nonmalignant.png';
import Meningioma from './assets/Meningioma.png';
import Atypicalteratoid from './assets/Atypicalteratoid.png';

// Define styled components
const StyledTopicContainer = styled.div`
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    margin-top: 50px;
`;

const StyledTopic = styled.div`
    font-family: 'Dongle', sans-serif;
    color: #5F6C7B;
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

const BarContainer = styled.div`
    display: flex;
    flex-wrap: wrap;
    margin-top: 10px;
`;

const Bar = styled.div`
    width: 10px;
    height: 20px;
    background-color: ${props => props.isFilled ? '#EF4565' : '#E5E7EB'};
    margin-right: 2px;
    margin-bottom: 2px;
`;

const BarRow = styled.div`
    display: flex;
    align-items: center;
    margin-bottom: 5px;
`;

const EntityName = styled.p`
    margin-left: 35px;
`;

function DataBar({ entity, count, maxCount }) {
    const barsPerRow = 70;
    const totalBars = count > barsPerRow ? Math.max(maxCount, barsPerRow) : barsPerRow;
    const filledBars = Array.from({ length: count }).map((_, i) => <Bar key={`filled-${i}`} isFilled={true} />);
    const emptyBars = Array.from({ length: totalBars - count }).map((_, i) => <Bar key={`empty-${i}`} isFilled={false} />);

    const allBars = [...filledBars, ...emptyBars];

    const barRows = [];
    for (let i = 0; i < Math.ceil(allBars.length / barsPerRow); i++) {
        barRows.push(
            <BarRow key={i}>
                {allBars.slice(i * barsPerRow, (i + 1) * barsPerRow)}
                {i === 0 && <EntityName>{entity}</EntityName>}
            </BarRow>
        );
    }

    return <div>{barRows}</div>;
}

function Topic({ title, children }) {
    return (
        <StyledTopic>
            <StyledHeader>{title}</StyledHeader>
            <StyledParagraph>{children}</StyledParagraph>
        </StyledTopic>
    );
}

function HomePage({ headerName }) {
    const [counts, setCounts] = useState({ total: 0, control: 0, positive: 0 });
    const [tumorEntities, setTumorEntities] = useState([]);

    useEffect(() => {
        axios.get('/api/project-data/')
            .then(response => {
                const fetchedData = response.data;
                setCounts({
                    total: fetchedData.total_samples,
                    control: fetchedData.control_samples,
                    positive: fetchedData.positive_samples
                });

                setTumorEntities(fetchedData.tumor_entities.map(item => ({
                    entity: item.entity_type,
                    count: item.count
                })));
            })
            .catch(error => console.error('Error fetching project data:', error));
    }, []);

    const maxCount = Math.max(...tumorEntities.map(e => e.count), 70);

    return (
        <div style={{ paddingLeft: 40, paddingRight: 40, paddingBottom: 40 }}>
            <StyledHeader>{headerName}</StyledHeader>
            <StyledTopicContainer>
                <Topic title="cfDNA Sequencing Analysis">
                    INTEGRATING SNAKEMAKE WORKFLOW WITH ADVANCED FRAGMENTOMICS FEATURES FOR NEXT-GENERATION SEQUENCING ANALYSIS OF CELL-FREE DNA IDENTIFIES ACTIONABLE INSIGHTS
                </Topic>
            </StyledTopicContainer>
            <StyledTopicContainer>
                <Topic title={`${counts.total} Samples`}>
                    Control {counts.control} Samples<br />Positive {counts.positive} Samples
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
                    <div>
                        {tumorEntities.map(entity => (
                            <DataBar key={entity.entity} entity={entity.entity} count={entity.count} maxCount={maxCount} />
                        ))}
                    </div>
                </Topic>
            </StyledTopicContainer>
        </div>
    );
}

export default HomePage;
