// postprocess.js
const path = require('path');
const fs = require('fs').promises;

async function replace() {
    // Paths
    const indexPath = path.resolve(__dirname, 'dist/index.html');

    // Read files
    const html = await fs.readFile(indexPath);

    const scriptsToAdd = `
    <style>
        /* Using a class for the canvas element */
        .canvas-style {
            display: block;
            position: absolute;
            left: 0;
            top: 60px;
        }

        /* Alternatively, using a direct selector for the canvas element */
        #canvas {
            display: block;
            position: absolute;
            left: 0;
            top: 60px;
        }
        </style>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet"
      integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"
      integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>

        <link rel='manifest' href='index.manifest.json'>
        <script src="index.js"></script>
    `
    // Replace placeholder
    const replaced = html.toString().replace('<div id="root"></div>', `<div id="root"></div>\n${scriptsToAdd}`);

    // Write back to the HTML file
    await fs.writeFile(indexPath, replaced);
}

replace();
