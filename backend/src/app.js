require('dotenv').config();
const express = require('express');
const connectDB = require('./config/db.js');

const app = express();
const port = process.env.PORT || 3000;

connectDB();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});

module.exports = app;