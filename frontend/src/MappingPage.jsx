import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import styled, { createGlobalStyle } from 'styled-components';
import { Select, Upload, Button, Divider, message } from 'antd';
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

function MappingPage() {
    const [sampleName, setSampleName] = useState('');
    const [fileList, setFileList] = useState([]);
    const [firstSetFileName, setFirstSetFileName] = useState('');
    const [secondSetFileName, setSecondSetFileName] = useState('');
    const navigate = useNavigate();
  
    const handleFileUpload = (event, uid) => {
      const file = event.target.files[0];
      if (file) {
        const fileName = file.name;
        if (uid === '1') {
          setFirstSetFileName(fileName);
        } else if (uid === '2') {
          setSecondSetFileName(fileName);
        }
        message.success(`${fileName} file uploaded successfully`);
      }
    };
  
    const handleDeleteFile = (uid) => {
      if (uid === '1') {
        setFirstSetFileName('');
        document.getElementById('first-set-upload').value = '';
      } else if (uid === '2') {
        setSecondSetFileName('');
        document.getElementById('second-set-upload').value = '';
      }
    };
  
    const handleRunTool = async (event) => {
      event.preventDefault();
  
      const formData = new FormData();
      formData.append('sample_name', sampleName);
      fileList.forEach(file => {
        formData.append('files', file);
      });
  
      try {
        await axios.post('http://localhost:8000/api/upload-to-gcs/', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        });
  
        const response = await axios.post('http://localhost:8000/api/create-project-data/', {
          sample_name: sampleName,
        });
  
        if (response.data.status === 'success') {
          alert(`Data saved successfully with sample_id: ${response.data.sample_id}`);
          navigate('/History');
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
          <Title>Mapping</Title>
        </StyledTopic>
        <BoxContainer>
          <Label>Sample name</Label>
          <StyledInput
            placeholder="Enter Sample name"
            value={sampleName}
            onChange={(e) => setSampleName(e.target.value)}
          />
        </BoxContainer>
  
        <BoxContainer>
          <Label>Select first set of reads</Label>
          <UploadContainer style={{ fontSize: '26px', color: '#5F6C7B', fontFamily: 'Dongle', fontWeight: '400' }}>
            <Box>
              <StyledText>{firstSetFileName || 'No file selected'}</StyledText>
              {firstSetFileName && (
                <DeleteButton onClick={() => handleDeleteFile('1')}><CloseCircleFilled /></DeleteButton>
              )}
            </Box>
            {/* <Upload
              fileList={fileList}
              beforeUpload={file => {
                setFileList([...fileList, file]);
                return false;
              }}
            > */}
              <label htmlFor="first-set-upload">
                <UploadOutlined
                  style={{
                    fontSize: '20px',
                    marginTop: '4px',
                    marginLeft: '20px',
                    padding: '9px',
                    color: '#fffffe',
                    backgroundColor: '#3DA9FC',
                    borderRadius: '10px',
                    cursor: 'pointer',
                  }}
                />
                <input type="file" id="first-set-upload" style={{ display: 'none' }} onChange={(e) => handleFileUpload(e, '1')} />
              </label>
            {/* </Upload> */}
          </UploadContainer>
        </BoxContainer>
  
        <BoxContainer>
          <Label>Select second set of reads</Label>
          <UploadContainer style={{ fontSize: '26px', color: '#5F6C7B', fontFamily: 'Dongle', fontWeight: '400' }}>
            <Box>
              <StyledText>{secondSetFileName || 'No file selected'}</StyledText>
              {secondSetFileName && (
                <DeleteButton onClick={() => handleDeleteFile('2')}><CloseCircleFilled /></DeleteButton>
              )}
            </Box>
            {/* <Upload
              fileList={fileList}
              beforeUpload={file => {
                setFileList([...fileList, file]);
                return false;
              }}
            > */}
              <label htmlFor="second-set-upload">
                <UploadOutlined
                  style={{
                    fontSize: '20px',
                    marginTop: '4px',
                    marginLeft: '20px',
                    padding: '9px',
                    color: '#fffffe',
                    backgroundColor: '#3DA9FC',
                    borderRadius: '10px',
                    cursor: 'pointer',
                  }}
                />
                <input type="file" id="second-set-upload" style={{ display: 'none' }} onChange={(e) => handleFileUpload(e, '2')} />
              </label>
            {/* </Upload> */}
          </UploadContainer>
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
            -  FastQ (all quality encoding variants)<br />
            -  Casava FastQ files*<br />
            -  Colorspace FastQ<br />
            -  GZip compressed FastQ<br />
          </div>
        </AcceptedFormatsContainer2>
      </div>
    );
  }

export default MappingPage;