// postprocess.js
const path = require('path');
const fs = require('fs').promises;

async function replace() {
    // Paths
    const indexPath = path.resolve(__dirname, 'dist/index.html');

    // Read files
    const html = await fs.readFile(indexPath);

    // Replace placeholder
    const replaced = html.toString().replace('<div id="root"></div>', `<div id="root"></div>\n<script src="/index.js"></script>`);

    // Write back to the HTML file
    await fs.writeFile(indexPath, replaced);
}

replace();
