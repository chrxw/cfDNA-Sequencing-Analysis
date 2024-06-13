import React from 'react';
import { useLocation } from 'react-router-dom';
import styled from 'styled-components';
import { Button, message, Popconfirm, Modal, Input } from 'antd';
import { EditOutlined, CloseOutlined, DownloadOutlined, DeleteOutlined } from '@ant-design/icons';
import './App.css';

// Styled component for the container
const Container = styled.div`
    min-height: 1270px;
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
    width: ${(props) => props.width || '105px'};
   
    height: 27px;
    padding-left: 14px;
    padding-right: 13px;
    border-radius: 20px;
    overflow: hidden;
    border: 1px solid ${(props) => props.borderColor};
    
    display: flex;
    align-items: center;
    gap: 9px;
    margin-top: 10px;
    margin-left: 55px;
    margin-right: 15px;
`;

// status running
const StatusDot = styled.div`
    width: 10px;
    height: 10px;
    background: ${(props) => props.background};
    border-radius: 9999px;
`;

// status running
const StatusText = styled.div`
    color: ${(props) => props.color};
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


function HistoryPage2() {
  const location = useLocation();
  const { historyData } = location.state || {};

  // const [isModalVisible, setIsModalVisible] = useState(false);
  // const [newSampleName, setNewSampleName] = useState('');

  // Check if historyData exists
  if (!historyData) {
    return <div>No history data available.</div>;
  }

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

  const handleDownload = async (fileName) => {
    console.log('Attempting to download file:', fileName);
    try {
        const formattedFileName = fileName.endsWith('/') ? fileName.slice(0, -1) : fileName;
        const response = await fetch(`/api/download_file/${formattedFileName}`);
        if (!response.ok) {
            throw new Error('Download failed');
        }
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);

        const link = document.createElement('a');
        link.href = url;
        link.download = fileName;
        link.click();

        window.URL.revokeObjectURL(url);
    } catch (error) {
        console.error('Download error:', error);
    }
};
  
  const confirm = (e) => {
    console.log(e);
    message.success('Delete success');
  };
  
  const cancel = (e) => {
    console.log(e);
    message.error('Cancel Delete');
  };

  const renderInputFiles = (files) => {
    return files.map((file, index) => {
      const fileName = file.split('/').pop();
      return (
        <InputFileName key={index}>
          {fileName}
          <StyledButtonload
            icon={<DownloadOutlined />}
            onClick={() => handleDownload(file)}
          />
        </InputFileName>
      );
    });
  };

  const renderOutputFiles = (files) => {
    return files.map((file, index) => {
      const fileName = file.split('/').pop();
      return (
        <OutputFileName key={index}>
          {fileName}
          <StyledButtonload
            icon={<DownloadOutlined />}
            onClick={() => handleDownload(file)}
          />
        </OutputFileName>
      );
    });
  };

  const showRenameModal = () => {
    setNewSampleName(historyData.sample_name);
    setIsModalVisible(true);
  };

  const handleRename = async () => {
    if (newSampleName.length > 50 || !/^[a-zA-Z0-9-_]+$/.test(newSampleName)) {
      message.error('Invalid sample name. Please adhere to the naming rules.');
      return;
    }

    try {
      const response = await fetch(`/api/rename_sample`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ history_id: historyData.history_id, new_sample_name: newSampleName }),
      });

      if (response.ok) {
        message.success('Sample name updated successfully');
        setIsModalVisible(false);
        // Optionally refresh the page or update the state to reflect the new name
      } else {
        throw new Error('Rename failed');
      }
    } catch (error) {
      console.error('Rename error:', error);
      message.error('Rename failed');
    }
  };

  const handleCancel = () => {
    setIsModalVisible(false);
  };

  return (
    <Container>
      <ContentContainer>
        <RightContainer>
          <Title>{historyData.sample_name}</Title>
          <RightText>{historyData.tool_package}</RightText>
          <DateText>{historyData.transaction_date}</DateText>

          {/* Status */}
          <StatusContainer borderColor={getStatusColor(historyData.status)}>
            <StatusDot background={getStatusColor(historyData.status)} />
            <StatusText color={getStatusColor(historyData.status)}>
              {historyData.status}
            </StatusText>
          </StatusContainer>

          <StyledButton icon={<EditOutlined />} onClick={showRenameModal} />

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
          {historyData.input_files && renderInputFiles(historyData.input_files)}
        </InputContainer>
        <OutputContainer>
          <OutputTitle>Output</OutputTitle>
          {historyData.output_files && renderOutputFiles(historyData.output_files)}
        </OutputContainer>
      </ContentContainer>

      {/* <Modal
      visible={isModalVisible}
      onCancel={handleCancel}
      footer={null}
      maskStyle={{ background: 'rgba(0, 0, 0, 0.5)' }}
      title={
        <div style={{ fontSize: '30px', fontFamily: 'Dongle', fontWeight: 400 }}>
          Rename {historyData.sample_name}
          <CloseOutlined onClick={handleCancel} style={{ float: 'right', cursor: 'pointer' }} />
        </div>
      }
      >
        <div style={{ fontSize: '30px', fontFamily: 'Dongle', fontWeight: 400, color: '#5f6c7b' }}>
          Rename this analysis record. You provide a name no longer than 50 characters in length, using only letters, numbers, dashes, and underscores.
        </div>
        <Input
          value={newSampleName}
          onChange={(e) => setNewSampleName(e.target.value)}
          placeholder={`New ${historyData.sample_name}`}
          maxLength={50}
          style={{ marginTop: '10px' }}
        />
        <div style={{ marginTop: '20px', textAlign: 'right' }}>
          <Button
            onClick={handleRename}
            style={{ borderColor: '#5f6c7b', borderRadius: '10px', backgroundColor: '#fffffe', color: '#094067', marginRight: '10px' }}
          >
            Save
          </Button>
          <Button
            onClick={handleCancel}
            style={{ borderRadius: '10px', backgroundColor: '#ef4565', color: '#fffffe' }}
          >
            Cancel
          </Button>
        </div>
      </Modal> */}

    </Container>
  );
}
export default HistoryPage2;