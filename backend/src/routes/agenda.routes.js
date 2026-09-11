const express = require('express');
const {
    getAgendas,
    getAgendaById,
    createAgenda,
    updateAgenda,
    deleteAgenda,
} = require('../controllers/agenda.controller.js');
const { protect } = require('../middleware/auth.middleware.js');

const router = express.Router();

router.use(protect);

router.route('/')
    .get(getAgendas)
    .post(createAgenda);

router.route('/:id')
    .get(getAgendaById)
    .put(updateAgenda)
    .delete(deleteAgenda);

module.exports = router;
