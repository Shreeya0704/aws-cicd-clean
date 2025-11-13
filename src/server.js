
const express = require('express');
const app = express();
app.get('/health', (_req, res) => res.status(200).json({ ok: true }));
app.get('/', (_req, res) => res.status(200).send('Hello from aws-cicd-clean!'));
module.exports = app;
