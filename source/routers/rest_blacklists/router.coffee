fs = require 'fs'
express = require 'express'
moment = require 'moment'

# =================================
# REST API to retrieve blacklists
# =================================

create_router = (config) ->

    router = express.Router()

    g_brands = config.brand_list
    blacklists = {}

    # -------------------------------------
    # Lists the REST methods of this router
    # -------------------------------------
    router.get '/', (req, res) ->
        path_list = ('/rest_blacklists' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}

    # ------------------------------------
    # QUERY blacklists filtering by brand
    # --------------------------------------
    router.get '/entries/brand/:brand', (req, res) ->

        allowed_values = ['--all--'].concat g_brands
        if req.params.brand not in allowed_values
            return res.json {error: "ERROR: Valor invàlid del paràmetre 'brand'. Possibles valors: #{allowed_values.join(', ')}"}
        
        col_name = 'brands'

        query = {}
        if req.params.brand isnt '--all--' then query['brand_name'] = req.params.brand
        config.mongo_cols['_brands'].find(query, {_id: 0}).sort({_id: 1}).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen dades amb els criteris indicats."}
                else
                    items.forEach (item) ->
                        blacklists[item.brand_name] = item.blacklist
                    res.json {result: blacklists}
            else
                res.json {error: err}
        
    router

module.exports = create_router
