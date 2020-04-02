fs = require 'fs'
express = require 'express'
moment = require 'moment'


# =======================================================================================
# REST API para Gestión del Diccionario de Influencers (está en un fichero, no en Mongo)
# =======================================================================================

create_router = (config) ->

    router = express.Router()

    g_brands = config.brand_list
    # -------------------------------------
    # Lista de métodos REST de este router
    # -------------------------------------
    router.get '/', (req, res) ->
        path_list = ('/rest_utils' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}


    # ---------------------------------------------
    # CONSULTA influencers filtrando por categoría
    # ---------------------------------------------
    router.get '/brands', (req, res) ->
        res.json {results: g_brands}

    router


module.exports = create_router
