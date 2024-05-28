import React, {useState, useEffect} from 'react';
import styled from 'styled-components';
import { EditOutlined, DeleteOutlined,DownloadOutlined  } from '@ant-design/icons';
import './App.css';
// import type { PopconfirmProps } from 'antd';
import { Button, message, Popconfirm } from 'antd';


// Styled component for the container
const Container = styled.div`
    min-height: 1025px;
    width: 100%;
    height: 100vh; /* Full height of the viewport */
    padding: 20px; /* Add some padding */
    box-sizing: border-box; /* Include padding in the element's total width and height */
    display: flex;
    align-items: flex-start; /* Align items to the top */
    // justify-content: space-between; /* Space out children */
`;

// Styled component for the title
const Title = styled.h1`
    width: 730px;
    color: #094067;
    font-size: 50px;
    font-family: Dongle;
    font-weight: 400;
    margin-top:15px;
    // margin-bottom: 20px; /* Add some space below the title */
    margin-left:33px;
`;

// Styled component for the right side container
const RightContainer = styled.div`
    display: flex;
    flex-direction: row; /* Align items horizontally */
    align-items: center; /* Center items vertically */
`;

// Styled component for the right side text
const RightText = styled.div`
    color: #5F6C7B;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
    word-wrap: break-word;
    // margin-left: 620px;
    margin-top: 17px;
    margin-right: 60px; /* Add space between the text and the date */
`;

// Styled component for the date
const DateText = styled.div`
    color: #5F6C7B;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
    word-wrap: break-word;
    margin-top: 17px;
`;

// status running
const StatusContainer = styled.div`
    width: 91px;
    height: 27px;
    padding-left: 12px;
    padding-right: 13px;
    border-radius: 20px;
    overflow: hidden;
    border: 1px solid #EF9745;
    display: flex;
    align-items: center;
    gap: 9px;
    margin-top: 10px;
    margin-left: 55px;
    margin-right: 15px;
`;
// color="#86EF45">Completed   color="#EF4565">Stopped  color="#EF9745">Running
// status running
const StatusDot = styled.div`
    width: 10px;
    height: 10px;
    background: #EF9745;
    border-radius: 9999px;
`;

// status running
const StatusText = styled.div`
    color: #EF9745;
    font-size: 20px;
    font-family: Dongle;
    font-weight: 400;
    word-wrap: break-word;
    margin-top: 3px;
`;

// status completed
const StatusContainercomp = styled.div`
    width: 110px;
    height: 27px;
    padding-left: 12px;
    padding-right: 13px;
    border-radius: 20px;
    overflow: hidden;
    border: 1px solid #86EF45;
    display: flex;
    align-items: center;
    gap: 9px;
    margin-top: 10px;
    margin-left: 55px;
    margin-right: 15px;
`;

// status completed
const StatusDotcomp = styled.div`
    width: 10px;
    height: 10px;
    background: #86EF45;
    border-radius: 9999px;
`;

// status completed
const StatusTextcomp     = styled.div`
    color: #86EF45;
    font-size: 20px;
    font-family: Dongle;
    font-weight: 400;
    word-wrap: break-word;
    margin-top: 3px;
`;

// status stop
const StatusContainerstop= styled.div`
    width: 96px;
    height: 27px;
    padding-left: 12px;
    padding-right: 13px;
    border-radius: 20px;
    overflow: hidden;
    border: 1px solid #EF4565;
    display: flex;
    align-items: center;
    gap: 9px;
    margin-top: 10px;
    margin-left: 55px;
    margin-right: 15px;
`;

// status stop
const StatusDotstop = styled.div`
    width: 10px;
    height: 10px;
    background: #EF4565;
    border-radius: 9999px;
`;

// status stop
const StatusTextstop    = styled.div`
    color: #EF4565;
    font-size: 20px;
    font-family: Dongle;
    font-weight: 400;
    word-wrap: break-word;
    margin-top: 3px;
`;

// Styled component for the button
const StyledButton = styled(Button)`
    margin-right: 10px;
    margin-top: 9px;
    border-color: transparent !important; /* Remove any border color */
    color: #3DA9FC;
`;

// Styled component for the button
const StyledButton2 = styled(Button)`
    margin-right: 10px;
    margin-top: 9px;
    border-color: transparent !important; /* Remove any border color */
    color: #ef4565 !important; /* Apply color with !important flag */

    &:active {
        color: #ef4565 !important; /* Change color when button is active */
    }
`;


// Styled component for the input container
const InputContainer = styled.div`
    width: 1370px;
    height: auto;
    border-radius: 10px;
    overflow: hidden;
    border: 1px solid #E5E7EB;
    flex-direction: column;
    justify-content: center;
    align-items: flex-start;
    display: inline-flex;
    margin-left:30px;
    margin-top: 30px; /* Adjust margin top as needed */
`;

// Styled component for the input title
const InputTitle = styled.div`
    height: auto; /* Increase the height */
    align-self: stretch;
    // flex: 1 1 0;
    padding-top: 6px;
    padding-bottom: 6px;
    padding-left: 30px;
    padding-right: 923px;
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
    overflow: hidden;
    border-bottom: 1px solid #E5E7EB;
    justify-content: flex-start;
    align-items: center;
    display: inline-flex;
    color: #094067;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
`;

// Styled component for the input file names
const InputFileName = styled.div`
    align-self: stretch;
    flex: 1 1 0;
    padding-top: 6px;
    padding-bottom: 6px;
    padding-left: 46px;
    padding-right: 803px;
    border-bottom: 1px solid #E5E7EB;
    justify-content: flex-start;
    align-items: center;
    display: inline-flex;
    color: #5F6C7B;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
`;
// Styled component for the parent container
const ContentContainer = styled.div`
    display: flex;
    flex-direction: column;
    align-items: flex-start;
`;
// Styled component for the output container
const OutputContainer = styled.div`
    width: 1370px;
    height: auto; /* Adjust height based on content */
    border-radius: 10px;
    overflow: hidden;
    border: 1px solid #E5E7EB;
    display: flex; /* Change display property to flex */
    flex-direction: column;
    
    align-items: flex-start;
    justify-content: center;
    margin-left: 30px; /* Adjust margin as needed */
    margin-top: 60px; /* Adjust margin as needed */
    // margin-bottom: 40px; /* Add margin bottom */
`;


// Styled component for the output title
const OutputTitle = styled.div`
    height: auto; /* Adjust height based on content */
    
    align-self: stretch;
    // flex: 1 1 0;
    padding-top: 6px;
    padding-bottom: 6px;
    padding-left: 30px;
    padding-right: 923px;
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
    overflow: hidden;
    border-bottom: 1px solid #E5E7EB;
    justify-content: flex-start;
    align-items: center;
    display: inline-flex;
    color: #094067;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
`;


// Styled component for the output file names
const OutputFileName = styled.div`
    align-self: stretch;
    flex: 1 1 0;
    display: flex; /* Change display property to flex */
    justify-content: space-between; /* Space out the children */
    padding-top: 6px;
    padding-bottom: 6px;
    padding-left: 46px;
    padding-right: 30px; /* Adjust right padding to align button properly */
    border-bottom: 1px solid #E5E7EB;
    align-items: center;
    color: #5F6C7B;
    font-size: 30px;
    font-family: Dongle;
    font-weight: 400;
`;



// Styled component for the button
const StyledButtonload = styled(Button)`
    
    // display: flex-end;
    // margin-left: 1150px;
    // margin-top: -1px;
    border-color: transparent !important; /* Remove any border color */
    color: #3DA9FC !important; /* Apply color with !important flag */
    margin-left: auto; /* Automatically margin-left to push the button to the right */
`;



// Function to handle download action
const handleDownload = (fileName) => {
    // Create a Blob with some text data
    const blob = new Blob([`Content of ${fileName}`], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);

    // Create a temporary anchor element
    const a = document.createElement('a');
    a.href = url;
    a.download = fileName;

    // Append the anchor to the body
    document.body.appendChild(a);
    // Programmatically click the anchor to trigger the download
    a.click();
    // Remove the anchor from the body
    document.body.removeChild(a);
};

message.config({
    className: 'custom-message',
});

const confirm = (e) => {
    console.log(e);
    message.success('Delete success');
};

const cancel = (e) => {
    console.log(e);
    message.error('Cancel Delete');
};

function HistoryPage2(props) {
    // Destructure the props object to access location
    const { location } = props;

    // Check if location.state exists and contains historyData
    if (!location || !location.state || !location.state.historyData) {
        return <div>No history data available.</div>;
    }

    // Check if historyData exists
    if (!historyData) {
        return <div style={{color: '#5F6C7B',
            fontSize: '35px',
            fontFamily: 'Dongle',
            fontWeight: '300',
            wordWrap: 'break-word',
            marginTop: '20px',
            marginLeft: '430px'}}>No history data available.</div>;
    }

    const { historyData } = location.state;

    return (
        <Container>
           
                <ContentContainer>
                    <RightContainer>
                        <Title>{historyData.sample_name}</Title>
                        <RightText>{historyData.tool}</RightText>
                        <DateText>{historyData.transaction_date}</DateText>

                        {/* running status */}
                        <StatusContainer>
                            <StatusDot />
                            <StatusText>Running</StatusText>
                        </StatusContainer>

                        {/* completed status */}
                        {/* <StatusContainercomp>
                            <StatusDotcomp />
                            <StatusTextcomp>Completed</StatusTextcomp>
                        </StatusContainercomp> */}

                        {/* stop stasus */}
                        {/* <StatusContainerstop>
                            <StatusDotstop />
                            <StatusTextstop>Stopped</StatusTextstop>
                        </StatusContainerstop> */}

                        <StyledButton icon={<EditOutlined />} />

                        <Popconfirm
                        overlayClassName="custom-popconfirm"
                        placement="right"
                        title="Delete the task"
                        description="Are you sure to delete this History?"
                        onConfirm={confirm}
                        onCancel={cancel}
                        okText="Yes"
                        cancelText="No" 
                        >
                        <StyledButton2 icon={<DeleteOutlined />} />
                        </Popconfirm>

                    </RightContainer>
                    <InputContainer>
                        <InputTitle>Input</InputTitle>
                        <InputFileName>PID1234_R1.fastq</InputFileName>
                        <InputFileName>PID1234_R2.fastq</InputFileName>
                    </InputContainer>
                    <OutputContainer>
                        <OutputTitle>Output</OutputTitle>
                        <OutputFileName>
                        PID1234_R1.html
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234_R1.html')}
                        />
                    </OutputFileName>
                    <OutputFileName>
                    PID1234_R1.zip
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234_R1.zip')}
                        />
                    </OutputFileName>
                    <OutputFileName>
                    PID1234_R2.html
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234_R2.html')}
                        />
                    </OutputFileName>
                    <OutputFileName>
                    PID1234_R2.zip
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234_R2.zip')}
                        />
                    </OutputFileName>
                    <OutputFileName>
                    PID1234.bam
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234.bam')}
                        />
                    </OutputFileName>
                    <OutputFileName>
                    PID1234.bam.bai
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234.bam.bai')}
                        />
                    </OutputFileName>
                    <OutputFileName>
                    PID1234bam_markdup.bam
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234bam_markdup.bam')}
                        />
                    </OutputFileName>
                    <OutputFileName>
                        PID1234ichorCNA.zip
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234ichorCNA.zip')}
                        />
                    </OutputFileName>
                    <OutputFileName>
                    PID1234report.html
                        <StyledButtonload
                            icon={<DownloadOutlined />}
                            onClick={() => handleDownload('PID1234report.html')}
                        />
                    </OutputFileName>
                    </OutputContainer>
                </ContentContainer>
          
            {/* Your footer component */}
        </Container>
    );
}
export default HistoryPage2;