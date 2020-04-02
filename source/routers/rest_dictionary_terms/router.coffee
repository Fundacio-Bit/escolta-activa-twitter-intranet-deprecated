express = require 'express'
moment = require 'moment'
moment.locale('ca')
mongodb = require 'mongodb'
Ngram = require 'node-ngram'

normalize_text = require './utils/__normalize_text'


# ==================================================
# REST API para Gestión del DICCIONARIO de términos
# ==================================================

create_router = (config) ->

    router = express.Router()

    # -------------------------------------
    # Lista de métodos REST de este router
    # -------------------------------------
    router.get '/', (req, res) ->
        path_list = ('/rest_dictionary' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}


    # -----------------------------------------------------------------------------
    # CONSULTA entradas del diccionario en MongoDB filtrando por marca y categoría
    # -----------------------------------------------------------------------------
    router.get '/entries/category/:category/brand/:brand', (req, res) ->

        # Chequeamos parámetros
        # ----------------------
        if req.params.category not in ['--all--'].concat config.dict_terms_cats
            return res.json {error: "Valor de 'category' desconegut. Valors permesos: --all--, #{config.dict_terms_cats.join ', '}"}

        if req.params.brand not in ['--all--'].concat config.brand_list
            return res.json {error: "Valor de 'brand' desconegut. Valors permesos: --all--, #{config.brand_list.join ', '}"}

        query = {}
        if req.params.category isnt '--all--' then query['category'] = req.params.category
        if req.params.brand isnt '--all--' then query['brand'] = req.params.brand

        config.mongo_cols['dictionary_terms'].find(query).sort({_canonical_name: 1}).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen dades amb els criteris indicats."}
                else
                    res.json {total: items.length, results: items}
            else
                res.json {error: err}


    # --------------------------------------------------------------
    # CONSULTA entrada del diccionario en MongoDB filtrando por _id
    # --------------------------------------------------------------
    router.get '/entries/id/:id', (req, res) ->
        query = {_id: mongodb.ObjectID(req.params.id)}

        config.mongo_cols['dictionary_terms'].find(query).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeix cap entrada amb l'ID especificat."}
                else
                    res.json {results: items}  # lo enviamos como array porque aprovecharemos el mismo template de la búsqueda de entradas (que filtra por marca y categoría) para renderizar
            else
                res.json {error: err}


    # -------------------------------------------
    # INSERTA entrada del diccionario en MongoDB
    #--------------------------------------------
    router.post '/entries', (req, res) ->

        # Procesamos datos enviados por POST
        # -----------------------------------
        if req.body.brand not in config.brand_list
            return res.json {error: "Marca desconocida: #{req.body.brand}"}

        else if req.body.category not in config.dict_terms_cats
            return res.json {error: "Categoría desconocida: #{req.body.category}"}

        else
            # ==============
            # Validación OK
            # ==============
            newDictionaryEntry = req.body

            query = {}
            query['category'] = req.body.category
            query['brand'] = req.body.brand

            config.mongo_cols['dictionary_terms'].find(query, {_id: 0, alias: 1, _canonical_name: 1}).toArray (err, items) ->
                if not err

                    # Comprobamos si hay alias repetidos para la marca y categoría
                    # -------------------------------------------------------------
                    alias_with_commas = items.map (x) -> x.alias
                    extracted_alias = []
                    alias_with_commas.forEach (aliases) ->
                        extracted_alias = extracted_alias.concat (al.trim() for al in aliases.split(','))

                    esta_repetido = false
                    alias_repetido = ''
                    for alias in extracted_alias
                        for new_alias in newDictionaryEntry.alias
                            if alias is new_alias
                                esta_repetido = true
                                alias_repetido = new_alias
                                break

                    if esta_repetido
                        return res.json {error: "L'&agrave;lies '#{alias_repetido}' ja existeix a MongoDB per la marca i categoria indicades."}

                    # Comprobamos si está repetido el nombre canónico para la marca y categoría
                    # ---------------------------------------------------------------------------
                    my_canonical = normalize_text newDictionaryEntry._canonical_name.trim().toLowerCase()

                    canonicals_list = items.map (x) ->
                        normalize_text x._canonical_name.trim().toLowerCase()

                    esta_repetido = false
                    canonical_repetido = ''
                    for canonic in canonicals_list
                        if my_canonical is canonic
                            esta_repetido = true
                            canonical_repetido = my_canonical
                            break

                    if esta_repetido
                        return res.json {error: "El nom canònic '#{canonical_repetido}' ja existeix a MongoDB per la marca i categoria indicades."}

                    # Todo Ok. Preparamos el resto de campos de la nueva entrada
                    # -----------------------------------------------------------
                    newDictionaryEntry.alias = newDictionaryEntry.alias.join ', '
                    newDictionaryEntry['created_by'] = 'admin'
                    newDictionaryEntry['creation_date'] = moment().format 'YYYY-MM-DD'
                    newDictionaryEntry['last_modified'] = moment().format 'YYYY-MM-DD'

                    # Insertamos entrada en MongoDB
                    # ------------------------------
                    config.mongo_cols['dictionary_terms'].insert newDictionaryEntry, (err, docInserted) ->
                        if not err
                            return res.json {ok: 'ok', id: docInserted.insertedIds[0]}
                        else
                            return res.json {error: err}

                else
                    return res.json {error: err}


    # ---------------------------------------------------------
    # MODIFICA el campo 'alias' de una entrada del diccionario
    # ---------------------------------------------------------
    router.put '/entries/id/:id', (req, res) ->
        _id = mongodb.ObjectID(req.params.id)
        updatedAlias = req.body.updatedAlias.join ', '

        # Sacamos categoría y marca de la entrada pasada como parámetro
        # --------------------------------------------------------------
        config.mongo_cols['dictionary_terms'].find({_id: _id}).toArray (err, items) ->
            if not err
                myentry = items[0]

                # Comprobamos si hay alias repetidos en MongoDB
                # ----------------------------------------------
                query = {}
                query['category'] = myentry.category
                query['brand'] = myentry.brand

                config.mongo_cols['dictionary_terms'].find(query).toArray (err, entries) ->
                    if not err
                        alias_without_myentry = entries.filter (x) -> x._id.toString() isnt req.params.id  # descartamos la propia entrada que vamos a actualizar
                        alias_with_commas = alias_without_myentry.map (x) -> x.alias
                        extracted_alias = []
                        alias_with_commas.forEach (aliases) ->
                            extracted_alias = extracted_alias.concat (al.trim() for al in aliases.split(','))

                        # Comprobamos si los alias a modificar están repetidos
                        # -----------------------------------------------------
                        esta_repetido = false
                        alias_repetido = ''
                        for alias in extracted_alias
                            for new_alias in req.body.updatedAlias
                                if alias is new_alias
                                    esta_repetido = true
                                    alias_repetido = new_alias
                                    break

                        if esta_repetido
                            return res.json {error: "L'àlies '#{alias_repetido}' ja existeix a MongoDB per una altra entrada del diccionari."}

                        # Modificamos alias, si no hay repetidos
                        # ---------------------------------------
                        config.mongo_cols['dictionary_terms'].update {_id: _id}, {$set: {alias: updatedAlias, last_modified: moment().format('YYYY-MM-DD')}}, (err, result) ->
                            if not err
                                res.json {results: 'OK!'}
                            else
                                res.json {error: err}

                    else
                        return res.json {error: err}

            else
                return res.json {error: err}


    # ----------------------------------------------------------
    # MODIFICA el campo 'status' de una entrada del diccionario
    # ----------------------------------------------------------
    router.get '/entries/id/:id/status/:status', (req, res) ->
        _id = mongodb.ObjectID(req.params.id)
        status = req.params.status
        if status isnt 'PENDENT' then status = ''

        # Modificamos status
        # -------------------
        config.mongo_cols['dictionary_terms'].update {_id: _id}, {$set: {status: status}}, (err, result) ->
            if not err
                res.json {results: 'OK!'}
            else
                res.json {error: err}


    # -----------------------------------------
    # BORRA entrada del diccionario en MongoDB
    #------------------------------------------
    router.get '/entries/delete/id/:id', (req, res) ->
        query = {_id: mongodb.ObjectID(req.params.id)}

        config.mongo_cols['dictionary_terms'].deleteOne query, (err, results) ->
            if not err
                if JSON.parse(results).ok? and JSON.parse(results).n is 1  # por lo visto results devuelve una cadena JSON
                    res.json {ok: 'ok'}
                else
                    res.json {error: "No s'ha pogut esborrar l'entrada."}
            else
                res.json {error: err}


    # -----------------------------------------------------------------
    # EXTRAE alias y hashtag candidatos a partir de un nombre canónico
    # -----------------------------------------------------------------
    router.get '/alias/canonical_name/:canonical_name', (req, res) ->

        # ----------------------------------------------------------
        # Procesamos el nombre canónico para sacar alias candidatos
        # ----------------------------------------------------------
        my_canonical = req.params.canonical_name

        # Normalizamos el texto
        # ----------------------
        my_canonical = normalize_text my_canonical

        # Sacamos unigramas
        # ------------------
        unigrams = (x.trim().toLowerCase() for x in my_canonical.split(/\s+/) when x.trim() isnt '')

        # Sacamos el primer hashtag antes de eliminar stopwords
        # ------------------------------------------------------
        main_hashtag = "##{unigrams.join('')}"

        # Eliminamos stopwords
        # ---------------------
        config.mongo_cols['_stopwords'].find({}, {_id: 0}).toArray (err, items) ->
            if not err

                # Serializamos y normalizamos las stopwords
                # ------------------------------------------
                stopwords = []
                items.forEach (x) ->
                    if normalize_text(x.stopword) not in stopwords
                        stopwords.push normalize_text(x.stopword)

                # Eliminamos stopwords de unigramas
                # ----------------------------------
                unigrams = unigrams.filter (x) -> x not in stopwords

                # Sacamos bigramas y trigramas
                # -----------------------------
                ngram = new Ngram {n: 2}
                bigrams = ngram.ngram unigrams.join(' ')
                trigrams = ngram.ngram unigrams.join(' '), 3

                # Ensamblamos ngramas
                # --------------------
                results = [].concat unigrams
                bigrams.forEach (x) -> if x.length is 2 then results.push x.join(' ')
                trigrams.forEach (x) -> if x.length is 3 then results.push x.join(' ')

                # Creamos hashtags
                # -----------------
                hashtags = []
                results.forEach (x) -> hashtags.push "##{x.replace /\s+/g, ''}"

                # Ensamblamos resultados
                # -----------------------
                results = results.concat hashtags

                res.json {results: results}

            else
                res.json {error: err}


    router


module.exports = create_router
