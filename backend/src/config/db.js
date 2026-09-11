const mongoose = require('mongoose');

// ---------------------------------------------------------------------------
// CONEXION A MONGODB
// ---------------------------------------------------------------------------
// Dos ajustes importantes para que la app no se quede esperando:
//
//   serverSelectionTimeoutMS: cuanto espera mongoose para encontrar el servidor
//   antes de dar error. Por defecto son 30s, demasiado para una app movil.
//
//   bufferCommands: false hace que una consulta falle al instante si no hay
//   conexion, en vez de quedarse encolada esperando. Sin esto, una peticion
//   con la base caida se cuelga y el cliente termina con un timeout generico.
// ---------------------------------------------------------------------------
const connectDB = async () => {
    mongoose.set('bufferCommands', false);

    const connection = await mongoose.connect(process.env.MONGO_URI, {
        serverSelectionTimeoutMS: 8000,
        socketTimeoutMS: 20000,
    });

    console.log(`MongoDB conectado: ${connection.connection.host}`);

    // Avisos por consola si la conexion se cae o vuelve mientras corre el server.
    mongoose.connection.on('disconnected', () => {
        console.warn('MongoDB se desconecto');
    });

    mongoose.connection.on('reconnected', () => {
        console.log('MongoDB se reconecto');
    });

    return connection;
};

/// True solo cuando la conexion esta lista para recibir consultas.
const isConnected = () => mongoose.connection.readyState === 1;

module.exports = connectDB;
module.exports.isConnected = isConnected;
