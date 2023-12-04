// postprocess.js
const path = require('path');
const fs = require('fs').promises;

async function replace() {
    // Paths
    const indexPath = path.resolve(__dirname, 'dist/index.html');

    // Read files
    const html = await fs.readFile(indexPath);

    const scriptsToAdd = `
        <link rel='manifest' href='index.manifest.json'>
        <script src="index.service.worker.js"></script>
        <script src="index.js"></script>
    `
    // Replace placeholder
    const replaced = html.toString().replace('<div id="root"></div>', `<div id="root"></div>\n${scriptsToAdd}`);

    // Write back to the HTML file
    await fs.writeFile(indexPath, replaced);
}

replace();
