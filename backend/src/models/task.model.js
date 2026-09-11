const mongoose = require('mongoose');

const TASK_STATUSES = ['pending', 'in_progress', 'completed', 'cancelled'];

const taskSchema = new mongoose.Schema({
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
        enum: TASK_STATUSES,
        default: 'pending',
    },
    agenda: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Agenda',
        required: true,
        index: true,
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true,
    },
}, { timestamps: true });

module.exports = mongoose.model('Task', taskSchema);
module.exports.TASK_STATUSES = TASK_STATUSES;
