const jwt = require('jsonwebtoken');
const User = require('../models/user.model.js');

const protect = async (req, res, next) => {
    try {
        const header = req.headers.authorization || '';

        if (!header.startsWith('Bearer ')) {
            return res.status(401).json({ message: 'No autorizado: falta el token' });
        }

        const decoded = jwt.verify(header.split(' ')[1], process.env.JWT_SECRET);
        const user = await User.findById(decoded.id);

        if (!user) {
            return res.status(401).json({ message: 'No autorizado: usuario inexistente' });
        }

        req.user = user;
        return next();
    } catch (error) {
        return res.status(401).json({ message: 'No autorizado: token invalido' });
    }
};

module.exports = { protect };
