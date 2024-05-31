import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import styled, { createGlobalStyle } from 'styled-components';
import { Select, Upload, Button, Divider, Checkbox } from 'antd';
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
    margin-top:2px;
  }
  .ant-select-selection-placeholder {
    font-size: 27px;
    font-family: Dongle;
    font-weight: 400;
    color: rgba(95, 108, 123, 0.5);
    text-indent: 10px;
    margin-left:-10px;
    margin-top:1px;
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

const CheckboxText = styled.p`
  font-size: 27px;
  color: #5F6C7B;
  padding-bottom: 30 px;
  align-items: center;
  margin-top: 5px;
  // margin-left: 10px;
`;


function CancerPredictionPage() {
  const [sampleName, setSampleName] = useState('');
  const [sampleType, setSampleType] = useState('');
  const [diagnosisGroup, setDiagnosisGroup] = useState('');
  const [entityType, setEntityType] = useState('');
  const [firstSetFileName, setFirstSetFileName] = useState('');
  const [secondSetFileName, setSecondSetFileName] = useState('');
  const [errors, setErrors] = useState({});
  const [selectAllChecked, setSelectAllChecked] = useState(false);
  const [showSelections, setShowSelections] = useState(true);
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

  const handleCheckboxChange = (checked) => {
    setSelectAllChecked(checked);
    setShowSelections(!checked);
    if (!checked) {
      setSampleType('');
      setDiagnosisGroup('');
      setEntityType('');
    }
  };

  const handleDeleteFile = (uid) => {
    if (uid === '1') {
      setFirstSetFileName('');
    } else if (uid === '2') {
      setSecondSetFileName('');
    }
  };

  const validateFields = () => {
    const newErrors = {};

    if (!sampleName) newErrors.sampleName = 'The field must not be empty';
    if (!firstSetFileName) newErrors.firstSetFileName = 'The field must not be empty';
    if (!secondSetFileName) newErrors.secondSetFileName = 'The field must not be empty';
    if (!sampleType) newErrors.sampleType = 'The field must not be empty';
    if (!diagnosisGroup) newErrors.diagnosisGroup = 'The field must not be empty';
    if (!entityType) newErrors.entityType = 'The field must not be empty';

    setErrors(newErrors);

    return Object.keys(newErrors).length === 0;
  };

  // Run tool button
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

      // Create new project data
      const response = await axios.post('/api/create-project-data-view/', {
        sample_name: sampleName,
        sample_type: sampleType,
        diagnosis_group: diagnosisGroup,
        entity_type: entityType
      });

      if (response.data.status === 'success') {
        alert(`Data saved successfully with sample_id: ${response.data.sample_id}`);
        // navigate('/History2');

        // Trigger the bioinformatics pipeline after navigating to History page
        // await axios.post('/api/trigger-pipeline/', {
        //   sample_name: sampleName,
        //   history_id: response.data.history_id });
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

      {/* Tool name */}
      <StyledTopic color="#094067">
        {/* <Title>Cancer Prediction</Title> */}
        <Title>{tool ? tool.tool_name : 'Cancer Prediction'}</Title>
      </StyledTopic>

      {/* Enter sample name */}
      <BoxContainer>
        <Label>Sample name</Label>
        <StyledInput
          placeholder="Enter Sample name"
          value={sampleName}
          onChange={(e) => setSampleName(e.target.value)}
        />
        {errors.sampleName && <ErrorMessage>{errors.sampleName}</ErrorMessage>}
      </BoxContainer>

      {/* Select first set of reads */}
      <BoxContainer>
        <Label>Select first set of reads</Label>
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
            accept='.fastq, .fastq.gz'
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
                // marginTop: '4px',
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

      {/* Select second set of reads */}
      <BoxContainer>
        <Label>Select second set of reads</Label>
        <UploadContainer style={{ fontSize: '26px', color: '#5F6C7B', fontFamily: 'Dongle', fontWeight: '400' }}>
          <Box>
            <StyledText>
              {!secondSetFileName && <span style={{ color: 'rgba(95, 108, 123, 0.5)' }}>No file selected</span>}
              {secondSetFileName || ''}
            </StyledText>
            {secondSetFileName && (
              <DeleteButton onClick={() => handleDeleteFile('2')}><CloseCircleFilled /></DeleteButton>
            )}
          </Box>
          <Upload
            accept='.fastq, .fastq.gz'
            maxCount={1}
            showUploadList={false}
            beforeUpload={file => {
              setSecondSetFileName(file.name);
              formData.append('files', file);
              return false
            }}
          >
            <UploadOutlined
              style={{
                fontSize: '20px',
                // marginTop: '4px',
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
        {errors.secondSetFileName && <ErrorMessage>{errors.secondSetFileName}</ErrorMessage>}
      </BoxContainer>

      {/* Checkbox for confirmation */}
      <BoxContainer>
        <Checkbox checked={selectAllChecked} onChange={(e) => handleCheckboxChange(e.target.checked)}>
          {selectAllChecked ? <CheckboxText>Please uncheck when you are aware of the sample's data type.</CheckboxText>: <CheckboxText>Please check when you are unaware of the sample's data type.</CheckboxText>}
        </Checkbox>
      </BoxContainer>

      {/* Selections */}
      {showSelections && (
        <>

          {/* Select sample type */}
          <BoxContainer>
            <Label>Sample Type</Label>
            <Select
              defaultValue={null}
              // value={sampleType}
              onChange={setSampleType}
              size="large"
              className="custom-select"
              style={{
                width: 806,
                height: 42,
                borderRadius: '10px',
                fontSize: '27px',
                border: '1px solid transparent',
                // marginLeft:'-10px',
              }}
              placeholder={<PlaceholderText>Select sample type</PlaceholderText>}
              options={[
                { value: 'control', label: 'Control' },
                { value: 'positive', label: 'Positive' }
              ]}
            />
            {errors.sampleType && <ErrorMessage>{errors.sampleType}</ErrorMessage>}
          </BoxContainer>

          {/* Select diagnosis group */}
          <BoxContainer>
            <Label>Diagnosis Group</Label>
            <Select
              defaultValue={null}
              // value={diagnosisGroup}
              onChange={setDiagnosisGroup}
              size="large"
              className="custom-select"
              style={{
                width: 806,
                height: 42,
                borderRadius: '10px',
                fontSize: '27px',
                border: '1px solid transparent',
                // marginLeft:'-10px',
              }}
              placeholder={<PlaceholderText>Select Diagnosis Group</PlaceholderText>}
              options={[
                { value: 'none', label: 'None' },
                { value: 'High Grade Glioma (incl.DIPG)', label: 'High Grade Glioma (incl.DIPG)' },
                { value: 'RMA', label: 'RMA' },
                { value: 'Medulloblastoma', label: 'Medulloblastoma' },
                { value: 'RME', label: 'RME' },
                { value: 'IMT', label: 'IMT' },
                { value: 'Ependymoma', label: 'Ependymoma' },
                { value: 'Ewing Sarcoma', label: 'Ewing Sarcoma' },
                { value: 'Sarcoma (NOS)', label: 'Sarcoma (NOS)' },
                { value: 'Osteosarcoma', label: 'Osteosarcoma' },
                { value: 'Other embryonal brain tumors', label: 'Other embryonal brain tumors' },
                { value: 'Hepatoblastoma', label: 'Hepatoblastoma' },
                { value: 'Neuroblastoma', label: 'Neuroblastoma' },
                { value: 'Rhabdoid Tumor (ATRT)', label: 'Rhabdoid Tumor (ATRT)' },
                { value: 'Kidney tumours', label: 'Kidney tumours' },
                { value: 'Germ cell tumors', label: 'Germ cell tumors' },
                { value: 'Desmoplastic Small Round Cell Tumor', label: 'Desmoplastic Small Round Cell Tumo' },
                { value: 'Other sarcomas ', label: 'Other sarcomas ' },
                { value: 'Other tumors', label: 'Other tumors' },
                { value: 'Other mesenchymal tumors', label: 'Other mesenchymal tumors' },
                { value: 'Acute myeloid leukemia', label: 'Acute myeloid leukemia' },
                { value: 'Other brain tumors', label: 'Other brain tumors' }
              ]}
            />
            {errors.diagnosisGroup && <ErrorMessage>{errors.diagnosisGroup}</ErrorMessage>}
          </BoxContainer>

          {/* Select entity type */}
          <BoxContainer>
            <Label>Entity Type</Label>
            <Select
              defaultValue={null}
              // value={entityType}
              onChange={setEntityType}
              size="large"
              className="custom-select"
              style={{
                width: 806,
                height: 42,
                borderRadius: '10px',
                fontSize: '27px',
                border: '1px solid transparent',
                // marginLeft:'-10px',
              }}
              placeholder={<PlaceholderText>Select Entity Type</PlaceholderText>}

              options={[
                { value: 'Brain tumors', label: 'Brain tumors' },
                { value: 'Sarcomas', label: 'Sarcomas' },
                { value: 'Neuroblastoma', label: 'Neuroblastoma' },
                { value: 'Hematolgical malignanciess', label: 'Hematolgical malignancies' },
                { value: 'Others', label: 'Others' }
              ]}
            />
            {errors.entityType && <ErrorMessage>{errors.entityType}</ErrorMessage>}
          </BoxContainer>
        </>
      )}

      {/* Run tool button */}
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

      {/* Accepted files formate */}
      <AcceptedFormatsContainer>
        <Divider orientation="left" plain>
          <AcceptedFormatsTitle>Accepted formats</AcceptedFormatsTitle>
        </Divider>
      </AcceptedFormatsContainer>

      <AcceptedFormatsContainer2>
        <div style={{ color: '#5F6C7B', fontSize: 20, fontFamily: 'Dongle', fontWeight: '400', wordWrap: 'break-word' }}>
          -  FastQ (all quality encoding variants)<br />
          -  Casava FastQ files*<br />
          -  Colorspace FastQ
        </div>
      </AcceptedFormatsContainer2>
    </div>
  );
}

export default CancerPredictionPage;