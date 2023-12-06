module.exports = function (app) {
    app.use((req, res, next) => {
        // Enable SharedArrayBuffer
        res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
        res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');

        // Remove existing headers if needed
        res.removeHeader('Cross-Origin-Resource-Policy');

        next();
    });
};
