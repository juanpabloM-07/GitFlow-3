const mongoose = require('mongoose');

const agendaSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
    },
    description: {
        type: String,
        required: true,
    },
    date: {
        type: Date,
        required: true,
    },
    time: {
        type: String,
        required: true,
    },
    status: {
        type: String,
        required: true,
        enum: ['pending', 'in_progress', 'completed', 'cancelled'],
    },
});

module.exports = mongoose.model('Agenda', agendaSchema);