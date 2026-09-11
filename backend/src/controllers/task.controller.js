const Agenda = require('../models/agenda.model.js');
const Task = require('../models/task.model.js');

const { TASK_STATUSES } = Task;

// Verifica que la agenda exista y pertenezca al usuario autenticado.
const findOwnedAgenda = (agendaId, userId) => Agenda.findOne({ _id: agendaId, user: userId });

const getTasks = async (req, res) => {
    try {
        const filter = { user: req.user._id };

        if (req.query.agenda) filter.agenda = req.query.agenda;
        if (req.query.status) filter.status = req.query.status;

        const tasks = await Task.find(filter).sort({ date: 1, time: 1 });

        return res.json(tasks);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const getTaskById = async (req, res) => {
    try {
        const task = await Task.findOne({ _id: req.params.id, user: req.user._id });
        if (!task) return res.status(404).json({ message: 'Tarea no encontrada' });

        return res.json(task);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const createTask = async (req, res) => {
    try {
        const { title, description, date, time, status, agenda } = req.body;

        if (!title || !date || !time || !agenda) {
            return res.status(400).json({ message: 'Titulo, fecha, hora y agenda son obligatorios' });
        }

        if (status && !TASK_STATUSES.includes(status)) {
            return res.status(400).json({ message: 'Estado invalido' });
        }

        if (!(await findOwnedAgenda(agenda, req.user._id))) {
            return res.status(404).json({ message: 'Agenda no encontrada' });
        }

        const task = await Task.create({
            title,
            description,
            date,
            time,
            status: status || 'pending',
            agenda,
            user: req.user._id,
        });

        return res.status(201).json(task);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const updateTask = async (req, res) => {
    try {
        if (req.body.status && !TASK_STATUSES.includes(req.body.status)) {
            return res.status(400).json({ message: 'Estado invalido' });
        }

        if (req.body.agenda && !(await findOwnedAgenda(req.body.agenda, req.user._id))) {
            return res.status(404).json({ message: 'Agenda no encontrada' });
        }

        const changes = {};
        ['title', 'description', 'date', 'time', 'status', 'agenda'].forEach((field) => {
            if (req.body[field] !== undefined) changes[field] = req.body[field];
        });

        const task = await Task.findOneAndUpdate(
            { _id: req.params.id, user: req.user._id },
            { $set: changes },
            { new: true, runValidators: true },
        );

        if (!task) return res.status(404).json({ message: 'Tarea no encontrada' });

        return res.json(task);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const deleteTask = async (req, res) => {
    try {
        const task = await Task.findOneAndDelete({ _id: req.params.id, user: req.user._id });
        if (!task) return res.status(404).json({ message: 'Tarea no encontrada' });

        return res.json({ message: 'Tarea eliminada', id: task._id });
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

module.exports = { getTasks, getTaskById, createTask, updateTask, deleteTask };
