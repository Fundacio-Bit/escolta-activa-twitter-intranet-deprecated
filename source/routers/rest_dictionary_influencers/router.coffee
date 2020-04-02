fs = require 'fs'
express = require 'express'
moment = require 'moment'


# ==============================================
# REST API to manage the influencers dictionary
# ==============================================

create_router = (config) ->

    router = express.Router()

    g_brands = config.brand_list
    g_influencers_categories = config.dictionary_influencers_categories
    fichero = config.context.dictionary_influencers_json

    # -------------------------------------
    # Lists the REST methods of this router
    # -------------------------------------
    router.get '/', (req, res) ->
        path_list = ('/rest_dictionary_influencers' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}


    # ---------------------------------------
    # QUERY influencers filtering by category
    # ----------------------------------------
    router.get '/entries/category/:category', (req, res) ->

        allowed_values = ['--all--'].concat g_influencers_categories
        if req.params.category not in allowed_values
            return res.json {error: "ERROR: Valor invàlid del paràmetre 'category'. Possibles valors: #{allowed_values.join(', ')}"}

        query = {}
        if req.params.category isnt '--all--' then query['category'] = req.params.category
        config.mongo_cols['dictionary_influencers'].find(query, {_id: 0}).sort({_id: 1}).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen dades amb els criteris indicats."}
                else
                    res.json {total: items.length, items: items}
            else
                res.json {error: err}

    # ------------------------------------------------------------------------------------------------
    # MODIFY (or INSERT) a list of influencers coming from the reportings section (edited by the user) 
    # ------------------------------------------------------------------------------------------------
    router.put '/entries', (req, res) ->

        # console.log "\nInvoque PUT..."
        dict_influencers = {}
        query = {}
        config.mongo_cols['dictionary_influencers'].find(query, {_id: 0}).sort({_id: 1}).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen dades amb els criteris indicats."}
                else
                    dict_influencers = items
                    dict_influencers_normalized_ids = dict_influencers.map (x) -> x.normalized_id

                    # flatten the influencers to update/insert
                    # ----------------------------------------
                    update_influencers = []
                    g_brands.forEach (brand) ->
                        if req.body.influencers[brand]?
                            req.body.influencers[brand].forEach (entry) ->
                                my_entry =
                                    influencer: entry.influencer
                                    category: entry.category
                                    subcategory: entry.subcategory
                                update_influencers.push my_entry

                    # iterate, check and insert or update the dictionary
                    # ---------------------------------------------------
                    bulk = config.mongo_cols['dictionary_influencers'].initializeUnorderedBulkOp()     
                    update_influencers.forEach (update_entry) ->
                        current_id = update_entry.influencer.toLowerCase().trim()
                        if current_id in dict_influencers_normalized_ids
                            # console.log 'Update    ' +  current_id
                            # update
                            # -------
                            bulk.find(normalized_id: current_id).update $set:
                                category: update_entry.category
                                subcategory: update_entry.subcategory
                                last_update: moment().format 'YYYY-MM-DD'
                        else
                            # console.log 'Insert  ' + update_entry.influencer
                            # Insert
                            # -----------
                            newDictionaryEntry = {}
                            newDictionaryEntry['normalized_id'] = current_id
                            newDictionaryEntry['influencer'] = update_entry.influencer
                            newDictionaryEntry['category'] = update_entry.category
                            newDictionaryEntry['subcategory'] = update_entry.subcategory
                            newDictionaryEntry['creation_date'] = moment().format 'YYYY-MM-DD'
                            newDictionaryEntry['last_update'] = moment().format 'YYYY-MM-DD'
                            bulk.insert newDictionaryEntry

                    bulk.execute (err, result) ->
                        if not err
                            res.json {ok: 'ok'}
                        else
                            return res.json {error: err}

            else
                res.json {error: err}

    # -------------------------------------------
    # INSERTA entrada del diccionario en MongoDB
    #--------------------------------------------
    router.post '/entries', (req, res) ->

        newDictionaryEntry = req.body
        normalized_id = req.body.influencer.toLowerCase().trim()

        # Check for duplicates
        query = {}
        query['normalized_id'] = normalized_id
        
        config.mongo_cols['dictionary_influencers'].find(query, {influencer: 1}).toArray (err, items) ->
            if not err
                if items.length > 0
                    return res.json {error: "El influencer '#{req.body.influencer}' ja existeix a MongoDB."}
                else
                    # Todo Ok. Preparamos el resto de campos de la nueva entrada
                    # -----------------------------------------------------------
                    newDictionaryEntry['category'] = 'turisme_oci'
                    newDictionaryEntry['normalized_id'] = normalized_id
                    newDictionaryEntry['creation_date'] = moment().format 'YYYY-MM-DD'
                    newDictionaryEntry['last_update'] = moment().format 'YYYY-MM-DD'

                    # Insertamos entrada en MongoDB
                    # ------------------------------
                    config.mongo_cols['dictionary_influencers'].insert newDictionaryEntry, (err, docInserted) ->
                        if not err
                            return res.json {ok: 'ok', id: docInserted.insertedIds[0]}
                        else
                            return res.json {error: err}
            else
                return res.json {error: err}


    # --------------------------------------------------------------------------------------------
    # MODIFICA el campo 'subcategory' de una entrada de la colección del diccionariode influencers
    # --------------------------------------------------------------------------------------------
    router.put '/update', (req, res) ->

        influencer = req.body.influencer
        normalized_id = influencer.toLowerCase().trim()
        category = req.body.category
        subcategory = req.body.subcategory

        # Sacamos categoría y marca de la entrada pasada como parámetro
        # --------------------------------------------------------------
        col_name = 'dictionary_influencers'

        config.mongo_cols[col_name].update {normalized_id: normalized_id}, {$set: {category: category, subcategory: subcategory, last_update: moment().format 'YYYY-MM-DD'}}, (err, result) ->
            if not err
                res.json {result: 'OK!'}
            else
                res.json {error: err}


    # --------------------------------------------------------------------------------------------
    # ELIMINA un influencer de la colección del diccionario de influencers
    # --------------------------------------------------------------------------------------------
    router.get '/delete/id/:id', (req, res) ->

        normalized_id = req.params.id.toLowerCase().trim()

        # Remove influencer
        collection_name = 'dictionary_influencers'
        config.mongo_cols[collection_name].deleteOne {'normalized_id': normalized_id}, (err, results) ->
            if not err
                res.json {results: 'OK!'}
            else
                res.json {error: "S'ha produït un error eliminant el influencer a MongoDB. Contacti amb l'administrador." + err}



    router

module.exports = create_router
