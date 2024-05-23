import React, { useState } from 'react';
import { BrowserRouter as Router, Route, Routes, Link } from 'react-router-dom';
import { Layout, Menu } from 'antd';
import { HomeOutlined, UploadOutlined, FunnelPlotOutlined, DashboardOutlined, HistoryOutlined, SettingOutlined } from '@ant-design/icons';
import logoSrc from './assets/Logo.png';

import './App.css';

// Import your pages/components
import HomePage from './HomePage';
// import UploadPage from './UploadPage';
import AnalysisCenter from './AnalysisCenter';
import DashboardPage from './DashboardPage';
import HistoryPage from './HistoryPage';
import SettingsPage from './SettingsPage';
import CancerPredictionPage from './CancerPredictionPage';
import QualityControlPage from './QualityControlPage';
import MappingPage from './MappingPage';
import SortingPage from './SortingPage';
import MarkDuplicatesPage from './MarkDuplicatesPage';
import IndexingPage from './IndexingPage';
import CNVCallingPage from './CNVCallingPage';

const { Header, Content, Footer, Sider } = Layout;

function App() {
  const [selectedMenuKey, setSelectedMenuKey] = useState('1'); // State to track the selected menu item
  const [headerName, setHeaderName] = useState('Home'); // State to track the header name

  const handleMenuClick = (event) => {
    setSelectedMenuKey(event.key); // Update the selected menu item key
    // Update the header name based on the selected menu item
    switch (event.key) {
      case '1':
        setHeaderName('Home');
        break;
      // case '2':
      //   setHeaderName('Upload Data');
      //   break;
      case '3':
        setHeaderName('Analysis Center');
        break;
      case '4':
        setHeaderName('Dashboard');
        break;
      case '5':
        setHeaderName('History');
        break;
      case '6':
        setHeaderName('Setting');
        break;
      default:
        setHeaderName('Home');
        break;
    }
  };

  return (
    <Router>
      <Layout>
        <Sider
          width={330}
          style={{
            overflow: 'auto',
            height: '100vh',
            position: 'fixed', left: 0, top: 0, bottom: 0,
            background: '#fffffe',
            borderRight: '1px solid #E5E7EB'
          }}
        >
          {/* Logo */}
          <div className="logoContainer">
            <img src={logoSrc} alt="Logo" className="logo" />
            <h1 className="csa">CSA</h1>
          </div>

          {/* cfDNA Sequencing Analysis */}
          <div className="cfDNA">
            <h1 className="csa-fullname">cfDNA Sequencing Analysis</h1>
          </div>

          {/* Navigation Menu */}
          <Menu
            className="navigation-menu"
            mode="inline"
            selectedKeys={[selectedMenuKey]}
            onClick={handleMenuClick}
            style={{ height: '82%', display: 'flex', flexDirection: 'column', borderRight: 'none' }}
          >
            <Menu.Item key="1" icon={<HomeOutlined />}>
              <Link to="/">Home</Link>
            </Menu.Item>
            {/* <Menu.Item key="2" icon={<UploadOutlined />}>
              <Link to="/upload">Upload Data</Link>
            </Menu.Item> */}
            <Menu.Item key="3" icon={<FunnelPlotOutlined />}>
              <Link to="/Analysis">Analysis Center</Link>
            </Menu.Item>
            <Menu.Item key="4" icon={<DashboardOutlined />}>
              <Link to="/Dashboard">Dashboard</Link>
            </Menu.Item>
            <Menu.Item key="5" icon={<HistoryOutlined />}>
              <Link to="/History">History</Link>
            </Menu.Item>
            <div style={{ flexGrow: 1 }}></div>
            <Menu.Item key="6" icon={<SettingOutlined />}>
              <Link to="/Settings">Setting</Link>
            </Menu.Item>
          </Menu>

        </Sider>

        <Layout className="site-layout" style={{ marginLeft: 330, paddingLeft: 40, background: '#fffffe' }}>
          <Header className="site-bottom">
            {headerName}
          </Header>
          <Content>
            <div className="site-layout-background" style={{ padding: 0, minHeight: 790 }}>
              <Routes>
                <Route path="/" element={<HomePage />} />
                {/* <Route path="/upload" element={<UploadPage />} /> */}
                <Route path="/Analysis" element={<AnalysisCenter />} />
                <Route path="/Dashboard" element={<DashboardPage />} />
                <Route path="/History" element={<HistoryPage />} />
                <Route path="/Settings" element={<SettingsPage />} />
                <Route path="/CancerPrediction" element={<CancerPredictionPage />} />
                <Route path="/QualityControl" element={<QualityControlPage />} />
                <Route path="/Mapping" element={<MappingPage />} />
                <Route path="/Sorting" element={<SortingPage />} />
                <Route path="/MarkDuplicates" element={<MarkDuplicatesPage />} />
                <Route path="/Indexing" element={<IndexingPage />} />
                <Route path="/CNVCalling" element={<CNVCallingPage />} />
              </Routes>
            </div>
          </Content>
          <Footer className="site-footer">
            cfDNA Sequencing Analysis ©2024 Created by No22-HDS
          </Footer>
        </Layout>
      </Layout>
    </Router>
  );
}

export default App;
