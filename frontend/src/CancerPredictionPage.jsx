import React, { useState } from 'react';
import styled, { createGlobalStyle } from 'styled-components';
import { Input, Select, Upload, Button, message } from 'antd';
import { UploadOutlined } from '@ant-design/icons';
import axios from 'axios';

// Create a global style to adjust the font size of the options in Select
const GlobalSelectStyle = createGlobalStyle`
  .ant-select-item-option-content {
    font-size: 27px; // Adjust the font size as needed
    font-family: Dongle;
    font-weight: 400;
    color: rgba(95, 108, 123, 1);
    text-indent: 10px; /* Adjust the value as needed */
  } 

  .ant-select-selection-item {
    font-size: 27px; // Adjust the font size of selected option text
    font-family: Dongle;
    font-weight: 400;
    color: rgba(95, 108, 123, 1);
    text-indent: 10px; /* Adjust the value as needed */
  }
`;

// Styled component for the placeholder text
const PlaceholderText = styled.span`
  font-size: 27px; // Adjust the font size of the placeholder text
  color: rgba(95, 108, 123, 0.5); // Placeholder text color
  padding-left: 10px; /* Adjust the value as needed */
`;

// Styled component for the topic
const StyledTopic = styled.div`
  font-family: 'Dongle', sans-serif;
  color: ${({ color }) => color || '#094067'};
  font-weight: 400; /* Add font weight */
`;

// Styled component for the input box
const StyledInput = styled.input`
  width: 806px;
  height: 39px;
  border-radius: 10px;
  border: 1px solid #094067;
  padding: 10px; /* Add padding to match the height of the div */
  font-size: 26px;
  color: rgba(95, 108, 123, 1);
  font-family: Dongle;
  font-weight: 400;

  /* Placeholder style */
  &::placeholder {
    color: rgba(95, 108, 123, 0.5);
  }

  /* Adjust position of text */
  text-indent: 10px; /* Adjust the value as needed */
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
  width: 837px;
  flex-direction: column; /* Adjust to column layout */
  align-items: flex-start;
  margin-bottom: 20px;
  margin-left: 30px;
`;

// Styled component for the label
const Label = styled.div`
  font-size: 32px;
  font-weight: bold;
  margin-bottom: 10px;
  color: #5F6C7B;
  font-family: Dongle;
  font-weight: 400;
  word-wrap: break-word;
`;

// Styled component for the box-like structure
const Box = styled.div`
  flex: 1; /* Grow to fill available space */
  height: 39px;
  border-radius: 10px;
  border: 1px solid #094067;
  display: flex;
  align-items: center;
  padding: 0 10px; /* Add padding */
`;

// Styled component for the upload button container
const UploadContainer = styled.div`
  display: flex;
  align-items: center;
  justify-content: flex-end; /* Align items to the right */
  width: 100%; /* Ensure it occupies the full width */
`;

function CancerPredictionPage() {
  const [workflowName, setWorkflowName] = useState('');
  const [firstSetFileName, setFirstSetFileName] = useState('');
  const [secondSetFileName, setSecondSetFileName] = useState('');

  const handleUpload = async (file, setFileName) => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('workflow_name', workflowName);

    try {
      const response = await axios.post('http://localhost:8000/upload/', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      setFileName(response.data.file_path);
      message.success(`${file.name} file uploaded successfully`);
    } catch (error) {
      message.error(`${file.name} file upload failed.`);
    }
  };

  const beforeUpload = (file) => {
    const allowedFileTypes = ['fastq', 'fastq.gz', 'fasta'];
    const fileExtension = file.name.split('.').pop();
    if (allowedFileTypes.includes(fileExtension)) {
      return true;
    }
    message.error(`Invalid file type. Only .fastq, .fastq.gz, or .fasta files are allowed.`);
    return false;
  };

  const uploadProps = {
    beforeUpload: (file) => {
      return false; // Prevent auto upload by returning false
    },
    customRequest: async ({ file, onSuccess, onError }) => {
      try {
        await handleUpload(file, setFirstSetFileName);
        onSuccess("ok");
      } catch (error) {
        onError("error");
      }
    },
  };

  const uploadPropsSecond = {
    beforeUpload: (file) => {
      return false; // Prevent auto upload by returning false
    },
    customRequest: async ({ file, onSuccess, onError }) => {
      try {
        await handleUpload(file, setSecondSetFileName);
        onSuccess("ok");
      } catch (error) {
        onError("error");
      }
    },
  };

  return (
    <div style={{ padding: 40 }}>
      {/* Apply the global select style */}
      <GlobalSelectStyle />

      <StyledTopic color="#094067">
        <Title>Cancer Prediction</Title>
      </StyledTopic>
      {/* Box 1: Workflow name */}
      <BoxContainer>
        <Label>Workflow name</Label>
        <StyledInput
          placeholder="Fill your workflow name"
          value={workflowName}
          onChange={(e) => setWorkflowName(e.target.value)}
        />
      </BoxContainer>

      {/* Box 3: Select first set of reads */}
      <BoxContainer>
        <Label>Select first set of reads</Label>
        <UploadContainer>
          <Box>{firstSetFileName}</Box>
          <Upload {...uploadProps}>
            <Button icon={<UploadOutlined style={{ color: 'white' }} />} style={{ background: '#3DA9FC' }}></Button>
          </Upload>
        </UploadContainer>
      </BoxContainer>

      {/* Box 4: Select second set of reads */}
      <BoxContainer>
        <Label>Select second set of reads</Label>
        <UploadContainer>
          <Box>{secondSetFileName}</Box>
          <Upload {...uploadPropsSecond}>
            <Button icon={<UploadOutlined style={{ color: 'white' }} />} style={{ background: '#3DA9FC' }}></Button>
          </Upload>
        </UploadContainer>
      </BoxContainer>

      {/* Box 5: Sample type */}
      <BoxContainer>
        <Label>Sample type</Label>
        <Select
          className="custom-select"
          style={{
            width: 806,
            height: 42,
            fontSize: '32px',
            borderRadius: '10px', // Add border-radius
            border: '1px solid transparent', // Set border to transparent
          }}
          placeholder={<PlaceholderText>Select Sample type</PlaceholderText>}
          options={[
            { value: '1', label: 'Control' },
            { value: '2', label: 'Positive' }
          ]}
        />
      </BoxContainer>

      {/* Box 6: Diagnosis group */}
      <BoxContainer>
        <Label>Diagnosis group</Label>
        <Select
          className="custom-select"
          style={{
            width: 806,
            height: 42,
            fontSize: '32px',
            borderRadius: '10px', // Add border-radius
            border: '1px solid transparent', // Set border to transparent
          }}
          placeholder={<PlaceholderText>Select Diagnosis group</PlaceholderText>}
          options={[
            { value: '1', label: 'Low-grade glioma' },
            { value: '2', label: 'Ependymoma' },
            { value: '3', label: 'Medulloblastoma' },
            { value: '4', label: 'Other' },
            { value: '5', label: 'High-grade glioma' },
            { value: '6', label: 'Diffuse intrinsic pontine glioma' },
            { value: '7', label: 'Non-malignant' },
            { value: '8', label: 'Meningioma' },
            { value: '9', label: 'Atypical teratoid rhabdoid tumor' }
          ]}
        />
      </BoxContainer>

      {/* Box 7: Entity type */}
      <BoxContainer>
        <Label>Entity type</Label>
        <Select
          className="custom-select"
          style={{
            width: 806,
            height: 42,
            fontSize: '32px',
            borderRadius: '10px', // Add border-radius
            border: '1px solid transparent', // Set border to transparent
          }}
          placeholder={<PlaceholderText>Select Entity type</PlaceholderText>}
          options={[
            { value: '1', label: 'Brain cancer' },
            { value: '2', label: 'Sarcoma cancer' },
            { value: '3', label: 'Neuroblastoma' },
            { value: '4', label: 'Hematolgical malignancies' },
            { value: '5', label: 'other' },
          ]}
        />
      </BoxContainer>
    </div>
  );
}

export default CancerPredictionPage;
