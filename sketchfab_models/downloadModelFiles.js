var script = document.createElement('script');
script.src = 'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.5/jszip.min.js';
document.head.appendChild(script);

function downloadAndZipFiles() {
    // List of file URLs to download
    const fileUrls = [
        'file.binz',
        'model_file.binz',
        'model_file_wireframe.binz'
    ];

    // Create a new instance of JSZip
    const zip = new JSZip();

    // Function to download a file and add it to the zip
    async function downloadAndAddToZip(url, filename) {
        const response = await fetch(url);
        const data = await response.arrayBuffer();
        zip.file(filename, data);
    }

    // Download each file and add it to the zip
    const downloadPromises = fileUrls.map((url, index) => {
        const filename = `file${index + 1}.binz`;
        return downloadAndAddToZip(url, filename);
    });

    // After all files are downloaded and added to the zip, create the zip file
    Promise.all(downloadPromises)
        .then(() => {
            // Generate the zip file
            zip.generateAsync({ type: 'blob' })
                .then(blob => {
                    // Create a link element for downloading the zip file
                    const link = document.createElement('a');
                    link.href = URL.createObjectURL(blob);
                    link.download = 'downloaded_files.zip';

                    // Append the link to the document and trigger the click event
                    document.body.appendChild(link);
                    link.click();

                    // Remove the link from the document
                    document.body.removeChild(link);
                })
                .catch(error => {
                    console.error('Error generating zip file:', error);
                });
        })
        .catch(error => {
            console.error('Error downloading files:', error);
        });
}

// Call the function when needed, e.g., when a button is clicked
downloadAndZipFiles();