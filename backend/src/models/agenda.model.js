const mongoose = require('mongoose');

const agendaSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true,
    },
    description: {
        type: String,
        default: '',
        trim: true,
    },
    color: {
        type: String,
        default: '#2563EB',
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true,
    },
}, { timestamps: true });

module.exports = mongoose.model('Agenda', agendaSchema);
