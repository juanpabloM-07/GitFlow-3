const jwt = require('jsonwebtoken');
const User = require('../models/user.model.js');

const signToken = (userId) => jwt.sign(
    { id: userId },
    process.env.JWT_SECRET,
    { expiresIn: '7d' },
);

const register = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({ message: 'Nombre, email y contrasena son obligatorios' });
        }

        const exists = await User.findOne({ email: email.toLowerCase() });
        if (exists) {
            return res.status(409).json({ message: 'Ya existe una cuenta con ese email' });
        }

        const user = await User.create({ name, email, password });

        return res.status(201).json({
            token: signToken(user._id),
            user: user.toPublicJSON(),
        });
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: 'Email y contrasena son obligatorios' });
        }

        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user || !(await user.comparePassword(password))) {
            return res.status(401).json({ message: 'Credenciales invalidas' });
        }

        return res.json({
            token: signToken(user._id),
            user: user.toPublicJSON(),
        });
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const me = async (req, res) => {
    return res.json({ user: req.user.toPublicJSON() });
};

module.exports = { register, login, me };