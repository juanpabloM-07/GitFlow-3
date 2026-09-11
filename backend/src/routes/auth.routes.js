const express = require('express');
const { register, login, me } = require('../controllers/auth.controller.js');
const { protect } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, me);

module.exports = router;