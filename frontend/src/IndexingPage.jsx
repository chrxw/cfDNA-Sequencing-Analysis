import React, { useState, useEffect  } from 'react';
import { useNavigate, useLocation  } from 'react-router-dom';
import styled, { createGlobalStyle } from 'styled-components';
import { Upload, Button, Divider } from 'antd';
import { UploadOutlined, CaretRightOutlined, CloseCircleFilled } from '@ant-design/icons';
import axios from 'axios';

const GlobalSelectStyle = createGlobalStyle`
  .ant-select-item-option-content {
    font-size: 27px;
    font-family: Dongle;
    font-weight: 400;
    color: rgba(95, 108, 123, 1);
    text-indent: 10px;
  }

  .ant-select-selection-item {
    font-size: 27px;
    font-family: Dongle;
    font-weight: 400;
    color: rgba(95, 108, 123, 1);
    text-indent: 10px;
  }
`;

const PlaceholderText = styled.span`
  font-size: 27px;
  color: rgba(95, 108, 123, 0.5);
  padding-left: 10px;
`;

const StyledTopic = styled.div`
  font-family: 'Dongle', sans-serif;
  color: ${({ color }) => color || '#094067'};
  font-weight: 400;
`;

const StyledInput = styled.input`
  width: 806px;
  height: 39px;
  border-radius: 10px;
  border: 1px solid #094067;
  padding: 10px;
  font-size: 26px;
  color: rgba(95, 108, 123, 1);
  font-family: Dongle;
  font-weight: 400;

  &::placeholder {
    color: rgba(95, 108, 123, 0.5);
  }

  text-indent: 10px;
`;

const Title = styled.h2`
  font-size: 50px;
  font-weight: 400;
  margin-bottom: 20px;
`;

const BoxContainer = styled.div`
  display: flex;
  width: 865px;
  flex-direction: column;
  align-items: flex-start;
  margin-bottom: 20px;
  margin-left: 30px;
`;

const Label = styled.div`
  font-size: 32px;
  font-weight: bold;
  margin-bottom: 10px;
  color: #5F6C7B;
  font-family: Dongle;
  font-weight: 400;
  word-wrap: break-word;
`;

const Box = styled.div`
  flex: 1;
  height: 39px;
  border-radius: 10px;
  border: 1px solid #094067;
  display: flex;
  align-items: center;
  padding: 0 10px;
`;

const UploadContainer = styled.div`
  display: flex;
  align-items: center;
  justify-content: flex-end;
  width: 100%;
  height: 45px;
`;

const ButtonContainer = styled.div`
  display: flex;
  justify-content: flex-start;
  width: 837px;
  margin-left: 30px;
`;

const AcceptedFormatsContainer = styled.div`
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  margin-top: 20px;
  margin-left: -50px;
`;

const AcceptedFormatsTitle = styled.div`
  text-align: center;
  color: #094067;
  font-size: 25px;
  font-family: Dongle;
  font-weight: 400;
  word-wrap: break-word;
`;

const AcceptedFormatsContainer2 = styled.div`
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  margin-top: -10px;
  margin-left: 42px;
`;

const StyledText = styled.div`
  padding-left: 10px;

  &::placeholder {
    color: rgba(95, 108, 123, 0.5);
  }
`;

const DeleteButton = styled.button`
  background: none;
  border: none;
  color: #5F6C7B;
  font-size: 15px;
  margin-left: 10px;
  margin-top: 6px;
  cursor: pointer;

  &:active {
    color: #ef4565;
  }
`;

const ErrorMessage = styled.div`
  color: #ef4565;
  font-size: 20px;
  font-family: Dongle;
  font-weight: 400;
  margin-top: 5px;
`;

function IndexingPage() {
  const [sampleName, setSampleName] = useState('');
  const [firstSetFileName, setFirstSetFileName] = useState('');
  const [errors, setErrors] = useState({});
  const navigate = useNavigate();
  const location = useLocation();
  const { tool_id } = location.state || {};
  const [tool, setTool] = useState(null);

  useEffect(() => {
    if (tool_id) {
      fetchToolData(tool_id);
    }
  }, [tool_id]);

  const fetchToolData = async (tool_id) => {
    try {
      const response = await axios.get(`/api/tools/${tool_id}`);
      setTool(response.data);
    } catch (error) {
      console.error('Error fetching tool data:', error);
    }
  };

  const handleDeleteFile = (uid) => {
    if (uid === '1') {
      setFirstSetFileName('');
    }
  };

  const validateFields = () => {
    const newErrors = {};

    if (!sampleName) newErrors.sampleName = 'The field must not be empty';
    if (!firstSetFileName) newErrors.firstSetFileName = 'The field must not be empty';

    setErrors(newErrors);

    return Object.keys(newErrors).length === 0;
  };

  const handleRunTool = async (event) => {
    event.preventDefault();

    if (!validateFields()) return;

    const formData = new FormData();
    formData.append('sample_name', sampleName);

    try {
      await axios.post('/api/upload-to-gcs/', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });

      const response = await axios.post('/api/create-project-data-view/', {
        sample_name: sampleName,
      });

      if (response.data.status === 'success') {
        alert(`Data saved successfully with sample_id: ${response.data.sample_id}`);
      } else {
        alert('Failed to save data');
      }
    } catch (error) {
      alert('An error occurred while saving data');
      console.error(error);
    }
  };

  return (
    <div style={{ padding: 40 }}>
      <GlobalSelectStyle />

      <StyledTopic color="#094067">
        <Title>{tool ? tool.tool_name : 'Indexing'}</Title>
      </StyledTopic>

      <BoxContainer>
        <Label>Sample name</Label>
        <StyledInput
          placeholder="Enter Sample name"
          value={sampleName}
          onChange={(e) => setSampleName(e.target.value)}
        />
        {errors.sampleName && <ErrorMessage>{errors.sampleName}</ErrorMessage>}
      </BoxContainer>

      <BoxContainer>
        <Label>Select set of reads</Label>
        <UploadContainer style={{ fontSize: '26px', color: '#5F6C7B', fontFamily: 'Dongle', fontWeight: '400' }}>
        <Box>
            <StyledText>
              {!firstSetFileName && <span style={{ color: 'rgba(95, 108, 123, 0.5)' }}>No file selected</span>}
              {firstSetFileName || ''}
            </StyledText>
            {firstSetFileName && (
              <DeleteButton onClick={() => handleDeleteFile('1')}><CloseCircleFilled /></DeleteButton>
            )}
          </Box>
          <Upload
            accept='.bam'
            maxCount={1}
            showUploadList={false}
            beforeUpload={file => {
              setFirstSetFileName(file.name);
              formData.append('files', file);
              return false
            }}
          >
            <UploadOutlined
              style={{
                fontSize: '20px',
                marginLeft: '20px',
                padding: '9px',
                color: '#fffffe',
                backgroundColor: '#3DA9FC',
                borderRadius: '10px',
                cursor: 'pointer',
              }}
            />
          </Upload>
        </UploadContainer>
        {errors.firstSetFileName && <ErrorMessage>{errors.firstSetFileName}</ErrorMessage>}
      </BoxContainer>

      <ButtonContainer>
        <Button
          type="primary"
          style={{
            background: '#3DA9FC',
            color: 'white',
            width: '123px',
            height: '45px',
            marginTop: '20px',
            borderRadius: '10px',
            fontSize: '25px',
            fontFamily: 'Dongle',
            fontWeight: '400',
            display: 'flex',
            alignItems: 'center',
          }}
          icon={<CaretRightOutlined style={{ marginRight: '-8px' }} />}
          onClick={handleRunTool}
        // disabled={!sampleName || !sampleType || !diagnosisGroup || !entityType || !firstSetFileName || !secondSetFileName}
        >
          <span style={{ marginTop: '4px' }}>Run Tool</span>
        </Button>
      </ButtonContainer>
  
      <AcceptedFormatsContainer>
        <Divider orientation="left" plain>
          <AcceptedFormatsTitle>Accepted formats</AcceptedFormatsTitle>
        </Divider>
      </AcceptedFormatsContainer>

      <AcceptedFormatsContainer2>
        <div style={{ color: '#5F6C7B', fontSize: 20, fontFamily: 'Dongle', fontWeight: '400', wordWrap: 'break-word' }}>
          -  .bam
        </div>
      </AcceptedFormatsContainer2>
    </div>
  );
}

export default IndexingPage;