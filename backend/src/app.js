require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db.js');

const authRoutes = require('./routes/auth.routes.js');
const agendaRoutes = require('./routes/agenda.routes.js');
const taskRoutes = require('./routes/task.routes.js');

const app = express();
const port = process.env.PORT || 3000;

// ---------------------------------------------------------------------------
// MIDDLEWARES BASE
// ---------------------------------------------------------------------------
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Log de cada peticion con su duracion. Sirve para saber si la app realmente
// llego al backend: si el celular marca timeout y aca no aparece nada, el
// problema es de red (IP equivocada o firewall), no del servidor.
app.use((req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
        console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode} (${Date.now() - start}ms)`);
    });

    next();
});

// ---------------------------------------------------------------------------
// RUTAS
// ---------------------------------------------------------------------------
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', db: connectDB.isConnected() });
});

// Si la base no esta conectada, cortamos aca con un 503 y un mensaje claro.
// Es mejor que dejar que la consulta falle sola varios segundos despues.
app.use('/api', (req, res, next) => {
    if (!connectDB.isConnected()) {
        return res.status(503).json({ message: 'La base de datos no esta disponible' });
    }

    next();
});

app.use('/api/auth', authRoutes);
app.use('/api/agendas', agendaRoutes);
app.use('/api/tasks', taskRoutes);

// ---------------------------------------------------------------------------
// ERRORES
// ---------------------------------------------------------------------------
app.use((req, res) => res.status(404).json({ message: 'Ruta no encontrada' }));

app.use((error, req, res, next) => {
    console.error(error);
    res.status(500).json({ message: error.message || 'Error interno del servidor' });
});

// ---------------------------------------------------------------------------
// ARRANQUE
// ---------------------------------------------------------------------------
// Primero conectamos a Mongo y recien despues escuchamos. Asi el servidor nunca
// acepta peticiones que no va a poder responder.
const start = async () => {
    try {
        await connectDB();

        // 0.0.0.0 escucha en todas las interfaces de red, no solo localhost.
        // Es lo que permite que un celular de la misma wifi pueda conectarse.
        app.listen(port, '0.0.0.0', () => {
            console.log(`Servidor escuchando en el puerto ${port}`);
        });
    } catch (error) {
        console.error('No se pudo conectar a MongoDB:', error.message);
        process.exit(1);
    }
};

start();

module.exports = app;
