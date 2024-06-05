//  SettingsPage.jsx
import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Link } from 'react-router-dom'; // Import the Link component
import styled from 'styled-components';
import { Button, Divider } from 'antd';
import { FunnelPlotOutlined, UploadOutlined, HistoryOutlined, } from '@ant-design/icons';
// import { Select, Upload, Button, Divider, Checkbox } from 'antd';
import './App.css';
import { Pagination } from 'antd';

import axios from 'axios';


// Styled component for the container to center the content
const Container = styled.div`
    width: 100%;
    // height: 100vh;
    // padding: 20px;
    padding-top: 30px;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
`;

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

    // Styled component for the button text
const ButtonText = styled.p`
    font-size: 35px;
    font-weight: 400;
    margin: 0; /* Remove default margin */
    margin-left: 10px; /* Adjust margin to create space between image and text */
`;

    // Styled component for the button
const StyledButton = styled(Button)`
    width: 450px;
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
    font-size: 23px;
    font-weight: 300;
    font-family: Dongle;
    word-wrap: break-word;
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

// Styled component for the box container
const BoxContainer = styled.div`
    width: 1370px;
    height: calc(100vh - 350px); /* มามําตรงนี้ปรับขนาดของกล่องshow history ได้ฮะ */
    border-radius: 10px;
    overflow-y: auto; /* Enable vertical scrolling if content overflows */
    border: 1px solid #E5E7EB;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: flex-start;
    // margin-left: 30px;
    margin-top: 20px;
`;

// Styled component for the box title
const BoxTitle = styled.div`
    height: auto;
    align-self: stretch;
    padding-top: 6px;
    padding-bottom: 6px;
    padding-left: 30px;
    padding-right: 30px;
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
    overflow: hidden;
    border-bottom: 1px solid #E5E7EB;
    justify-content: flex-start;
    align-items: center;
    display: flex;
    color: #5F6C7B;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
    cursor: pointer;
`;

const TitleColumn = styled.div`
    color: #094067;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
    flex: 1;
    text-align: left;

    &:nth-child(1) { flex: 2; } /* Adjust width for "Name" */
    &:nth-child(2) { flex: 3; } /* Adjust width for "Workflow" */
    &:nth-child(3) { flex: 1.5; } /* Adjust width for "Created" */
    &:nth-child(4) { flex: 1; } /* Adjust width for "Status" */
`;

const StatusContainer = styled.div`
    width: ${(props) => props.width || '106px'};
    height: 27px;
    border-radius: 20px;
    overflow: hidden;
    border: 1px solid ${(props) => props.borderColor};
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    margin-bottom: 3px;
`;

const StatusDot = styled.div`
    width: 10px;
    height: 10px;
    background: ${(props) => props.background};
    border-radius: 9999px;
`;

const StatusText = styled.div`
    color: ${(props) => props.color};
    font-size: 20px;
    font-family: Dongle;
    font-weight: 400;
    margin-top: 3px;
`;

const Titletext = styled.div`
    color: #5F6C7B;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
    flex: 1;
    text-align: left;
    &:nth-child(1) { flex: 2; }
    &:nth-child(2) { flex: 3; }
    &:nth-child(3) { flex: 1.5; }
    &:nth-child(4) { flex: 1; }
`;


function DashboardPage() {
    const navigate = useNavigate();
    const [historyData, setHistoryData] = useState([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize] = useState(10);

    
    useEffect(() => {
        fetch('/api/get_history_data/')
            .then(response => response.json())
            .then(data => {
                const sortedData = data.history_data.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
                setHistoryData(sortedData);
            })
            .catch(error => {
                console.error('Error fetching history data:', error);
            });
    }, []);

    const handleBoxTitleClick = (historyId) => {
        axios.get(`/api/display_history/${historyId}/`)
            .then(response => {
                console.log('Response:', response.data); // Log the response data
                const historyData = response.data.history_data;
                // Navigate to HistoryPage2 with historyData as state
                navigate('/HistoryPage2', { state: { historyData } });
            })
            .catch(error => {
                console.error('Error fetching history data:', error);
            });
    };

    const getStatusColor = (status) => {
        switch (status) {
            case 'Running':
                return '#EF9745';
            case 'Stopped':
                return '#EF4565';
            default:
                return '#86EF45';
        }
    };

    const paginatedData = historyData.slice((currentPage - 1) * pageSize, currentPage * pageSize);
    
    return (
        <div style={{ padding: 40, paddingTop: 70 }}>
            <StyledTopic color="#094067">
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 550px)', columnGap: '2px', rowGap: '20px' }}>
                    {/* Analysis tools */}
                    <ToolContainer>
                        <Link to="/CancerPrediction">
                            <StyledButton type="primary">
                                <UploadOutlined style={{ fontSize: '50px', color: '#fff', marginLeft: '15px', marginRight: '40px' }} />
                                <ButtonTextWrapper>
                                    <ButtonText>Upload Data</ButtonText>
                                    <ButtonDescription>Fastq format only</ButtonDescription>
                                </ButtonTextWrapper>
                            </StyledButton>
                        </Link>
                    </ToolContainer>
                    <ToolContainer>
                        <Link to="/Analysis">
                            <StyledButton type="primary">
                                <FunnelPlotOutlined style={{ fontSize: '50px', color: '#fff', marginLeft: '15px', marginRight: '40px' }} />
                                <ButtonTextWrapper>
                                    <ButtonText>Analysis Center</ButtonText>
                                    <ButtonDescription>Select bioinformatic tools</ButtonDescription>
                                </ButtonTextWrapper>
                            </StyledButton>
                        </Link>
                    </ToolContainer>
                    <ToolContainer>
                        <Link to="/History">
                            <StyledButton type="primary">
                                <HistoryOutlined style={{ fontSize: '50px', color: '#fff', marginLeft: '15px', marginRight: '40px' }} />
                                <ButtonTextWrapper>
                                    <ButtonText>View History</ButtonText>
                                    <ButtonDescription>View your workflow history</ButtonDescription>
                                </ButtonTextWrapper>
                            </StyledButton>
                        </Link>
                    </ToolContainer>
                </div>
            </StyledTopic>
            <Divider />
            <Container>
            <BoxContainer>
                <BoxTitle>
                    <TitleColumn>Name</TitleColumn>
                    <TitleColumn>Workflow</TitleColumn>
                    <TitleColumn>Created</TitleColumn>
                    <TitleColumn>Status</TitleColumn>
                </BoxTitle>

                {paginatedData.map((history) => (
                    <BoxTitle key={history.history_id} onClick={() => handleBoxTitleClick(history.history_id)}>
                        <Titletext>{history.history_name}</Titletext>
                        <Titletext>{history.tool}</Titletext>
                        <Titletext>{history.created_at}</Titletext>
                        <Titletext>
                            <StatusContainer borderColor={getStatusColor(history.status)}>
                                <StatusDot background={getStatusColor(history.status)} />
                                <StatusText color={getStatusColor(history.status)}>
                                    {history.status}
                                </StatusText>
                            </StatusContainer>
                        </Titletext>
                    </BoxTitle>
                ))}
            </BoxContainer>
            <Pagination
                current={currentPage}
                pageSize={pageSize}
                total={historyData.length}
                onChange={(page) => setCurrentPage(page)}
                style={{
                    marginTop: '20px',
                    marginLeft: 'auto', // Move Pagination to the right
                    marginRight: 'auto', // Move Pagination to the left
                    fontSize: '25px',
                    
                }}
            />
        </Container>

        </div>
    );
}

export default DashboardPage;