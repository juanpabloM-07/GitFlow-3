const Agenda = require('../models/agenda.model.js');
const Task = require('../models/task.model.js');

const getAgendas = async (req, res) => {
    try {
        const agendas = await Agenda.find({ user: req.user._id }).sort({ createdAt: -1 });

        // Cada agenda viaja con el conteo de tareas para poder pintarlo en la lista.
        const withCounts = await Promise.all(agendas.map(async (agenda) => {
            const [total, completed] = await Promise.all([
                Task.countDocuments({ agenda: agenda._id }),
                Task.countDocuments({ agenda: agenda._id, status: 'completed' }),
            ]);

            return { ...agenda.toObject(), taskCount: total, completedCount: completed };
        }));

        return res.json(withCounts);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const getAgendaById = async (req, res) => {
    try {
        const agenda = await Agenda.findOne({ _id: req.params.id, user: req.user._id });
        if (!agenda) return res.status(404).json({ message: 'Agenda no encontrada' });

        return res.json(agenda);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const createAgenda = async (req, res) => {
    try {
        const { title, description, color } = req.body;
        if (!title) return res.status(400).json({ message: 'El titulo es obligatorio' });

        const agenda = await Agenda.create({
            title,
            description,
            color,
            user: req.user._id,
        });

        return res.status(201).json(agenda);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const updateAgenda = async (req, res) => {
    try {
        const changes = {};
        ['title', 'description', 'color'].forEach((field) => {
            if (req.body[field] !== undefined) changes[field] = req.body[field];
        });

        const agenda = await Agenda.findOneAndUpdate(
            { _id: req.params.id, user: req.user._id },
            { $set: changes },
            { new: true, runValidators: true },
        );

        if (!agenda) return res.status(404).json({ message: 'Agenda no encontrada' });

        return res.json(agenda);
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

const deleteAgenda = async (req, res) => {
    try {
        const agenda = await Agenda.findOneAndDelete({ _id: req.params.id, user: req.user._id });
        if (!agenda) return res.status(404).json({ message: 'Agenda no encontrada' });

        // Borrado en cascada: una tarea sin agenda no tiene sentido.
        await Task.deleteMany({ agenda: agenda._id });

        return res.json({ message: 'Agenda eliminada', id: agenda._id });
    } catch (error) {
        return res.status(500).json({ message: error.message });
    }
};

module.exports = { getAgendas, getAgendaById, createAgenda, updateAgenda, deleteAgenda };
