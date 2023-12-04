import React, { useState, useEffect, useParams } from "react"
import ReactGodot from "./react-godot/src"
import { BrowserRouter as Router, Routes, Route, Link, useNavigate } from 'react-router-dom';

const examplePck = "/index"
const exampleEngine = "/index.js"

const SinglePlatform = () => {
  const handleDownload = async (platform) => {
    try {
      const versionMap = {
        'Mac': {
          versionName: "MacBuildV3",
          path: "/executables/mac/index.exe"
        },
        'Windows': {
          versionName: "WindowsBuildV1",
          path: "/executables/windows/index.exe"
        },
        'Linux': {
          versionName: "LinuxBuildV5",
          path: "/executables/linux/index.apk"
        },
        'Android': {
          versionName: "AndroidBuildV5",
          path: "/executables/android/index.apk"
        }
      };

      // Assuming the response contains the download URL
      const downloadUrl = versionMap[platform].path

      console.log(downloadUrl)

      // Generate a unique timestamp or version number
      const version = versionMap[platform].versionName + "__" + Date.now(); // You can use a more sophisticated versioning strategy if needed

      // Extract the file extension from the download URL
      const fileExtension = downloadUrl.split('.').pop();

      // Construct the desired file name with versioning
      const fileName = `Multiplayer_Experience_Test_${version}.${fileExtension}`;

      // Triggering file download
      const link = document.createElement('a');
      link.href = downloadUrl;
      link.target = '_blank'; // Open in a new tab/window if needed
      link.download = fileName;

      document.body.appendChild(link);
      link.click();

      // Cleanup
      document.body.removeChild(link);
    } catch (error) {
      alert(`Error processing your deposit. ${error.response.data.error}`);
    }
  };

  const { platform } = useParams();

  return (
    <div className='container px-4 py-5'>

      {/* {selectedProfile && <p>Selected Client: <b>{selectedProfile.firstName} {selectedProfile.lastName}</b></p>} */}
      {/* <p>Balance: <b>${balance}</b></p> */}

      <div className='mb-5'>
        {/* <p>Select your download type bellow:</p> */}
        <button className='btn btn-primary' onClick={() => handleDownload(platform)}>
          Download {platform} Executable
        </button>
      </div>

      
    </div>
  );
};

const GodotGame = () => {
  const iframeStyle = {
    width: '100%',
    height: '100vh', // Adjust the height as needed
    border: 'none', // Remove border for a cleaner look
    backgroundColor: '#f5f5f5',
    borderRadius: '12px',
    boxShadow: '0 0 15px rgba(0, 0, 0, 0.2)',
    overflow: 'hidden',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    cursor: 'pointer',
    transition: 'transform 0.3s ease-in-out',
    '&:hover': {
      transform: 'scale(1.05)',
    },
  };

  return (
    <div className="container-fluid" id="navbarSupportedContent">
      <ReactGodot style={iframeStyle} pck={examplePck} script={exampleEngine} />
    </div>
  );
};

function App() {
  return (
    <Router>
      <div className="App">
        <header className="App-header">
          <nav className="navbar navbar-expand-lg bg-body-tertiary">
            <div className="container-fluid">
              <Link className="navbar-brand" to="/">Multiplayer Experience Test</Link>
              <button
                className="navbar-toggler"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="#navbarSupportedContent"
                aria-controls="navbarSupportedContent"
                aria-expanded="false"
                aria-label="Toggle navigation"
              >
                <span className="navbar-toggler-icon" />
              </button>
              <div className="collapse navbar-collapse" id="navbarSupportedContent">
                <ul className="navbar-nav me-auto mb-2 mb-lg-0">
                  <li className="nav-item">
                    <Link className="nav-link active" aria-current="page" to="/">Web</Link>
                  </li>
                  <li className="nav-item">
                    <Link className="nav-link active" aria-current="page" to="/Windows">Windows</Link>
                  </li>
                  <li className="nav-item">
                    <Link className="nav-link active" aria-current="page" to="/Mac">Mac</Link>
                  </li>
                  <li className="nav-item">
                    <Link className="nav-link active" aria-current="page" to="/Linux">Linux</Link>
                  </li>
                  {/* <li className="nav-item">
                    <Link className="nav-link" to="/admin">Admin</Link>
                  </li> */}

                </ul>

              </div>
            </div>
          </nav>


        </header>

        <Routes>
          <Route path="/" element={<GodotGame />} />
          <Route path="/:platform" element={<SinglePlatform />} />
          {/* <Route path="/admin" element={<AdminPage />} /> */}
        </Routes>
      </div>
    </Router>
  )
  // return <ReactGodot pck={examplePck} script={exampleEngine} />
}

export default App
