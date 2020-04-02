express = require 'express'
PythonShell = require 'python-shell'
moment = require 'moment'
moment.locale('ca')
mongodb = require 'mongodb'
twix = require 'twix'
Promise = require('promise')

# =============================================================================
# REST API para extracción de tweets, retweets, recuentos de palabras y series
# =============================================================================

create_router = (config) ->

    router = express.Router()

    # -------------------------------------
    # Lista de métodos REST de este router
    # -------------------------------------
    router.get '/', (req, res) ->

        path_list = ('/rest_tweets_retweets' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}


    # -----------------------------------------------------------------------
    # Extrae retweets de MongoDB filtrando por Mes, Marca y Términos (alias)
    # -----------------------------------------------------------------------
    router.get '/retweets/yearmonth/:yearmonth/brand/:brand/terms/:terms', (req, res) ->

        # Chequeamos parámetros
        # ----------------------
        if not /^\d\d\d\d-\d\d$/.test(req.params.yearmonth)
            return res.json {error: "ERROR: Format de 'yearmonth' incorrecte. Format vàlid: 'YYYY-MM'."}

        if req.params.brand not in config.brand_list
            return res.json {error: "Valor de 'brand' desconegut. Valors permesos: #{config.brand_list.join ', '}"}

        year = /^(\d\d\d\d)-\d\d$/.exec(req.params.yearmonth)[1]
        col_name = 'twitter_daily_basic_counts_<year>'.replace '<year>', year

        if col_name not in (x for x of config.mongo_cols)
            return res.json {error: "No existeix col.lecció MongoDB per l'any <strong>#{year}</strong>"}

        terms = req.params.terms.replace /<hashtag>/g, '#'
        terms = (alias.trim().toLowerCase() for alias in terms.split(',') when alias.trim() isnt '')

        # Procedemos a extraer retweets
        # ------------------------------
        query = {}
        query['date'] = new RegExp('^'+req.params.yearmonth)
        projection = {}
        projection["_id"] = 0
        projection["date"] = 1
        projection["basic_counts.#{req.params.brand}.retweets"] = 1

        config.mongo_cols[col_name].find(query, projection).sort({date: 1}).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen dades pel 'yearmonth' indicat: <strong>#{req.params.yearmonth}</strong>"}
                else
                    # Formateamos resultados de retweets
                    # -----------------------------------
                    retweets = []

                    items.forEach (item) ->  # cada item es un doc de un día diferente

                        # Procesamos los retweets del día en curso
                        # -----------------------------------------
                        retweets_of_day = []
                        if req.params.brand in (x for x of item.basic_counts)
                            retweets_of_day = (val for key, val of item.basic_counts[req.params.brand].retweets)

                        # Filtramos por términos
                        # -----------------------
                        retweets_of_day = retweets_of_day.filter (retweet) ->
                            retweet_words = (x.trim().toLowerCase() for x in retweet.words.split(',') when x.trim() isnt '')
                            is_term_included = false
                            terms.forEach (term) ->
                                if term in retweet_words then is_term_included = true
                            is_term_included

                        # Ordenamos por recuento
                        # -----------------------
                        retweets_of_day.sort (a, b) -> b.count - a.count

                        if retweets_of_day.length > 0
                            new_day_bucket =
                                date: item.date
                                retweets: retweets_of_day
                            retweets.push new_day_bucket

                    my_total = 0
                    retweets.forEach (x) -> my_total += x.retweets.length

                    res.json {total: my_total, results: retweets}
            else
                res.json {error: err}

    # -----------------------------------------------------------------
    # Extrae retweets de MongoDB filtrando por mes y Marca
    # -----------------------------------------------------------------
    router.get '/viral_tweets/month/:month/brand/:brand', (req, res) ->

        # Chequeamos parámetros
        # ----------------------
        if not /^\d\d-\d\d$/.test(req.params.month)
            return res.json {error: "ERROR: Format de 'month' incorrecte."}
        month = /^(\d\d)-(\d\d)/.exec(req.params.month)[2]

        year = '20' + /^(\d\d)-\d\d/.exec(req.params.month)[1]  # se supone que el año es el mismo en start_date y end_date, chequeado por la parte cliente

        col_name = 'twitter_monthly_viral_tweets_<year>_<brand>'.replace('<year>', year).replace('<brand>', req.params.brand)

        if col_name not in (x for x of config.mongo_cols)
            return res.json {error: "No existeix col.lecció MongoDB per l'any <strong>#{year}</strong>"}

        if req.params.brand not in config.brand_list
            return res.json {error: "Valor de 'brand' desconegut. Valors permesos: #{config.brand_list.join ', '}"}

        query = {}
        # query["brand"] = req.params.brand
        query["month"] = year + "-" + month

        zero_pad = (number) ->
            if number < 10 
                number = '0' + number
            number

        projection = {}
        config.mongo_cols[col_name].find(query, projection).sort({touristic: -1 , count: -1}).toArray (err, tweets) ->
            if not err
                tweets.forEach (item) -> 
                    date_str = item['tweet_created_at'].getFullYear() + '-' + zero_pad(item['tweet_created_at'].getMonth() + 1) + '-' + zero_pad(item['tweet_created_at'].getDate())
                    item['tweet_created_at'] = date_str
                res.json {total: tweets.length, results: tweets}
            else
                res.json {error: err}

    # --------------------------------------------------------------------------------------------
    # MODIFICA una entrada de la colección viral tweets
    # --------------------------------------------------------------------------------------------
    router.put '/update', (req, res) ->
        # console.log JSON.stringify(req.body)
        month = req.body.month
        brand = req.body.brand
        tweet_id_str = req.body.tweet_id_str
        category = req.body.category
        canonical_name = req.body.canonical_name
        tweet_lang = req.body.tweet_lang

        month = /^(\d\d)-(\d\d)/.exec(req.body.month)[2]
        year = '20' + /^(\d\d)-\d\d/.exec(req.body.month)[1]  # se supone que el año es el mismo en start_date y end_date, chequeado por la parte cliente
        col_name = 'twitter_monthly_viral_tweets_<year>_<brand>'.replace('<year>', year).replace('<brand>', brand)


        query = {}
        query['tweet_id_str'] = tweet_id_str
        query["month"] = year + "-" + month
        newValue = {$set: {category: category, canonical_name: canonical_name, tweet_lang: tweet_lang}}

        config.mongo_cols[col_name].updateOne query, newValue, (err, result) ->
            if not err
                res.json {results: 'OK!'}
            else
                res.json {error: err}


    # ---------------------------------------------------------------------------------
    # Extrae la serie anual de recuentos de tweets (+ retweets) de una marca (o todas)
    # ---------------------------------------------------------------------------------
    router.get '/series/year/:year/brand/:brand', (req, res) ->

        # Chequeamos parámetros
        # ----------------------
        year = req.params.year
        if not /^\d\d\d\d$/.test(year)
            return res.json {error: "ERROR: Format de 'year' incorrecte. Format vàlid: 'YYYY'."}

        col_name = 'twitter_daily_basic_counts_<year>'.replace '<year>', year

        if col_name not in (x for x of config.mongo_cols)
            return res.json {error: "No existeix col.lecció MongoDB per l'any <strong>#{year}</strong>"}

        if req.params.brand is '--all--'
            my_brands = config.brand_list
        else if req.params.brand in config.brand_list
            my_brands = [req.params.brand]
        else
            return res.json {error: "Valor de 'brand' desconegut. Valors permesos: #{config.brand_list.join ', '}"}

        # Generamos array con todos los días del año en formato 'YYYY-MM-DD'
        # -------------------------------------------------------------------
        complete_year_dates = []
        iter = moment("#{year}-01-01").twix("#{year}-12-31").iterate(1, 'days')
        while iter.hasNext()
            complete_year_dates.push iter.next().format 'YYYY-MM-DD'


        complete_year_dates_names = Array.apply("", Array(365)).map ->""

        complete_year_dates_names[0]= "1 de gener"
        complete_year_dates_names[14]= "15 de gener"
        complete_year_dates_names[31]= "1 de febrer"
        complete_year_dates_names[45]= "15 de febrer"
        complete_year_dates_names[59]= "1 de març"
        complete_year_dates_names[73]= "15 de març"
        complete_year_dates_names[90]= "1 d'abril"
        complete_year_dates_names[104]= "15 d'abril"
        complete_year_dates_names[120]= "1 de maig"
        complete_year_dates_names[134]= "15 de maig"
        complete_year_dates_names[151]= "1 de juny"
        complete_year_dates_names[165]= "15 de juny"
        complete_year_dates_names[181]= "1 de juliol"
        complete_year_dates_names[195]= "15 de juliol"
        complete_year_dates_names[212]= "1 d'agost"
        complete_year_dates_names[226]= "15 d'agost"
        complete_year_dates_names[243]= "1 de setembre"
        complete_year_dates_names[257]= "15 de setembre"
        complete_year_dates_names[273]= "1 d'octubre"
        complete_year_dates_names[287]= "15 d'octubre"
        complete_year_dates_names[304]= "1 de novembre"
        complete_year_dates_names[318]= "15 de novembre"
        complete_year_dates_names[334]= "1 de desembre"
        complete_year_dates_names[349]= "15 de desembre"        
        
        # Sacamos los recuentos de tweets de MongoDB
        # -------------------------------------------
        query = {}
        projection = {}
        projection["_id"] = 0
        projection["date"] = 1
        my_brands.forEach (brand) ->
            projection["basic_counts.#{brand}.tweets"] = 1

        series = []

        config.mongo_cols[col_name].find(query, projection).sort({date: 1}).toArray (err, items) ->
            if not err

                # Sacamos los datos de serie por marca
                # -------------------------------------
                brand_colors =
                    mallorca:
                        borderColor: "rgba(255,255,0, 0.8)"
                        backgroundColor: "rgba(255,255,0,0)"
                    menorca:
                        borderColor: "rgba(0,128,0, 0.8)"
                        backgroundColor: "rgba(0,128,0,0)"
                    ibiza:
                        borderColor: "rgba(255,0,0,0.8)"
                        backgroundColor: "rgba(255,0,0,0)"
                    formentera:
                        borderColor: "rgba(0,0,255,0.8)"
                        backgroundColor: "rgba(0,0,255,0)"                       

                my_brands.forEach (brand) ->
                    datos = []

                    # Recorremos los días del año y comprobamos los tweets de la marca
                    # -----------------------------------------------------------------
                    complete_year_dates.forEach (date) ->
                        if date not in (x.date for x in items)
                            datos.push null
                        else
                            doc = items.filter((item) -> item.date is date)[0]
                            if doc.basic_counts[brand]?
                                # datos.push {x: x.date, y: doc.basic_counts[brand].tweets}
                                datos.push doc.basic_counts[brand].tweets                                    
                            else
                                # datos.push {x: x.date, y: 0}
                                datos.push 0

                    # Añadimos serie de la marca al array global de series
                    # -----------------------------------------------------
                    series.push {
                        label: brand,
                        borderColor: brand_colors[brand].borderColor,
                        backgroundColor: brand_colors[brand].backgroundColor,
                        # type: 'line',
                        borderWidth: 2,
                        tension: 0,
                        radius: 0,
                        data: datos}
    
                # Generamos serie en formato chartjs
                # ----------------------------------
                data = {
                    labels: complete_year_dates_names,
                    datasets : series
                }

                # Devolvemos resultado
                # ---------------------
                res.json {results: data}
            else
                res.json {error: err}


    # -----------------------------------------------------------------------------------------------
    # Extrae la serie anual de recuentos de términos (n-gram, hashtag o mention) filtrando por marca
    # Nota: Para un conjunto de términos separados por comas (como una entrada de diccionario)
    #       se acumularán sus recuentos por día al crear la serie.
    # -----------------------------------------------------------------------------------------------
    router.get '/series/year/:year/brand/:brand/terms/:terms', (req, res) ->

        # Chequeamos parámetros
        # ----------------------
        year = req.params.year
        if not /^\d\d\d\d$/.test(year)
            return res.json {error: "ERROR: Format de 'year' incorrecte. Format vàlid: 'YYYY'."}

        col_name = 'twitter_daily_basic_counts_<year>'.replace '<year>', year

        if col_name not in (x for x of config.mongo_cols)
            return res.json {error: "No existeix col.lecció MongoDB per l'any <strong>#{year}</strong>"}

        if req.params.brand not in config.brand_list
            return res.json {error: "Valor de 'brand' desconegut: #{req.params.brand}. Valors permesos: #{config.brand_list.join ', '}"}

        terms = req.params.terms.replace /<hashtag>/g, '#'
        terms = (alias.trim().toLowerCase() for alias in terms.split(',') when alias.trim() isnt '')

        # Generamos array con todos los días del año en formato 'YYYY-MM-DD'
        # -------------------------------------------------------------------
        complete_year_dates = []
        iter = moment("#{year}-01-01").twix("#{year}-12-31").iterate(1, 'days')
        while iter.hasNext()
            complete_year_dates.push iter.next().format 'YYYY-MM-DD'

        # Generamos array de nombres de fechas para poblar eje X de la serie
        # -------------------------------------------------------------------
        complete_year_dates_names = Array.apply("", Array(365)).map ->""

        complete_year_dates_names[0]= "1 de gener"
        complete_year_dates_names[14]= "15 de gener"
        complete_year_dates_names[31]= "1 de febrer"
        complete_year_dates_names[45]= "15 de febrer"
        complete_year_dates_names[59]= "1 de març"
        complete_year_dates_names[73]= "15 de març"
        complete_year_dates_names[90]= "1 d'abril"
        complete_year_dates_names[104]= "15 d'abril"
        complete_year_dates_names[120]= "1 de maig"
        complete_year_dates_names[134]= "15 de maig"
        complete_year_dates_names[151]= "1 de juny"
        complete_year_dates_names[165]= "15 de juny"
        complete_year_dates_names[181]= "1 de juliol"
        complete_year_dates_names[195]= "15 de juliol"
        complete_year_dates_names[212]= "1 d'agost"
        complete_year_dates_names[226]= "15 d'agost"
        complete_year_dates_names[243]= "1 de setembre"
        complete_year_dates_names[257]= "15 de setembre"
        complete_year_dates_names[273]= "1 d'octubre"
        complete_year_dates_names[287]= "15 d'octubre"
        complete_year_dates_names[304]= "1 de novembre"
        complete_year_dates_names[318]= "15 de novembre"
        complete_year_dates_names[334]= "1 de desembre"
        complete_year_dates_names[349]= "15 de desembre"   



        # Sacamos los recuentos de tweets de MongoDB
        # -------------------------------------------
        query = {}
        projection = {}
        projection["_id"] = 0
        projection["date"] = 1
        terms.forEach (term) ->
            projection["basic_counts.#{req.params.brand}.words.#{term}"] = 1

        datos = []
        totalCount = 0

        # Consulta a Mongo
        # ----------------
        config.mongo_cols[col_name].find(query, projection).sort({date: 1}).toArray (err, items) ->
            if not err

                # Recorremos los días del año y comprobamos si existen recuentos de terms
                # ------------------------------------------------------------------------
                complete_year_dates.forEach (date) ->
                    if date not in (x.date for x in items)
                        datos.push 0
                    else
                        doc = items.filter((item) -> item.date is date)[0]
                        if doc.basic_counts[req.params.brand]?

                            # recorremos términos (alias)
                            # ----------------------------
                            currentCount = 0
                            terms.forEach (term) ->
                                if doc.basic_counts[req.params.brand]['words'][term]?
                                    currentCount += doc.basic_counts[req.params.brand]['words'][term]

                            datos.push currentCount
                            totalCount += currentCount

                        else
                            datos.push 0

                # Generamos serie en formato chartjs
                # ----------------------------------
                data = {
                    labels: complete_year_dates_names,
                    datasets: [
                        borderColor: "rgba(124, 181, 236, 1)"
                        backgroundColor: "rgba(124, 181, 236, 0)"
                        borderWidth: 2
                        tension: 0
                        radius: 0                  
                        data: datos
                    ]
                }
                # Devolvemos resultado
                # ---------------------
                res.json {results: data}

            else
                res.json {error: err}


    # ---------------------------------------------------------------------------------
    # Extrae la serie anual de recuentos de tweets (+ retweets) de una marca (o todas)
    # ---------------------------------------------------------------------------------
    router.get '/series_filtrats/year/:year/brand/:brand', (req, res) ->
        # Chequeamos parámetros
        # ----------------------
        year = req.params.year
        if not /^\d\d\d\d$/.test(year)
            return res.json {error: "ERROR: Format de 'year' incorrecte. Format vàlid: 'YYYY'."}

        col_name = 'twitter_daily_basic_counts_<year>'.replace '<year>', year

        if col_name not in (x for x of config.mongo_cols)
            return res.json {error: "No existeix col.lecció MongoDB per l'any <strong>#{year}</strong>"}

        if req.params.brand is '--all--'
            my_brands = config.brand_list
        else if req.params.brand in config.brand_list
            my_brands = [req.params.brand]
        else
            return res.json {error: "Valor de 'brand' desconegut. Valors permesos: #{config.brand_list.join ', '}"}


        query = {}
        if req.params.brand isnt '--all--' then query['brand'] = req.params.brand

        config.mongo_cols['dictionary_terms'].find(query).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen terms amb els criteris indicats."}
                else
                    groupBy = (my_array, key) ->
                        my_array.reduce ((rv, x) ->
                            (rv[x[key]] = rv[x[key]] or []).push x
                            rv
                        ), {}
                    data_grouped = groupBy( items, 'brand')
                    g_dictionary_alias = []
                    my_brands.forEach (brand) ->
                        dictionary_alias = []
                        alias_list = []
                        data_grouped[brand].forEach (x) ->
                            alias = x.alias.split ','
                            dictionary_alias.push(al.trim() for al in alias)
                            alias_list = [].concat.apply([], dictionary_alias)
                        g_dictionary_alias.push({'brand': brand, 'alias': alias_list})

                    # Generamos array con todos los días del año en formato 'YYYY-MM-DD'
                    # -------------------------------------------------------------------
                    complete_year_dates = []
                    iter = moment("#{year}-01-01").twix("#{year}-12-31").iterate(1, 'days')
                    while iter.hasNext()
                        complete_year_dates.push iter.next().format 'YYYY-MM-DD'

                    # Generamos array de nombres de fechas para poblar eje X de la serie
                    # -------------------------------------------------------------------
                    complete_year_dates_names = Array.apply("", Array(365)).map ->""

                    complete_year_dates_names[0]= "1 de gener"
                    complete_year_dates_names[14]= "15 de gener"
                    complete_year_dates_names[31]= "1 de febrer"
                    complete_year_dates_names[45]= "15 de febrer"
                    complete_year_dates_names[59]= "1 de març"
                    complete_year_dates_names[73]= "15 de març"
                    complete_year_dates_names[90]= "1 d'abril"
                    complete_year_dates_names[104]= "15 d'abril"
                    complete_year_dates_names[120]= "1 de maig"
                    complete_year_dates_names[134]= "15 de maig"
                    complete_year_dates_names[151]= "1 de juny"
                    complete_year_dates_names[165]= "15 de juny"
                    complete_year_dates_names[181]= "1 de juliol"
                    complete_year_dates_names[195]= "15 de juliol"
                    complete_year_dates_names[212]= "1 d'agost"
                    complete_year_dates_names[226]= "15 d'agost"
                    complete_year_dates_names[243]= "1 de setembre"
                    complete_year_dates_names[257]= "15 de setembre"
                    complete_year_dates_names[273]= "1 d'octubre"
                    complete_year_dates_names[287]= "15 d'octubre"
                    complete_year_dates_names[304]= "1 de novembre"
                    complete_year_dates_names[318]= "15 de novembre"
                    complete_year_dates_names[334]= "1 de desembre"
                    complete_year_dates_names[348]= "15 de desembre"   


                    # Sacamos los recuentos de tweets de MongoDB
                    # -------------------------------------------
                    query = {}
                    projection = {}
                    projection["_id"] = 0
                    projection["date"] = 1

                    brand_colors =
                        mallorca:
                            borderColor: "rgba(255,255,0, 0.8)"
                            backgroundColor: "rgba(255,255,0,0)"
                        menorca:
                            borderColor: "rgba(0,128,0, 0.8)"
                            backgroundColor: "rgba(0,128,0,0)"
                        ibiza:
                            borderColor: "rgba(255,0,0,0.8)"
                            backgroundColor: "rgba(255,0,0,0)"
                        formentera:
                            borderColor: "rgba(0,0,255,0.8)"
                            backgroundColor: "rgba(0,0,255,0)"   

                    my_brands.forEach (brand) ->
                        projection["basic_counts.#{brand}.words"] = 1

                    series = []

                    config.mongo_cols[col_name].find(query, projection).sort({date: 1}).toArray (err, items) ->
                        if not err
                            serie_list = []
                            # Sacamos los datos de serie por marca
                            # -------------------------------------
                            my_brands.forEach (brand) ->

                                # Filtramos lista de alias de la marca
                                # ------------------------------------
                                alias_list = g_dictionary_alias.filter (x) -> x.brand == brand

                                # Recorremos los días del año y comprobamos los tweets de la marca
                                # -----------------------------------------------------------------
                                datos = []
                                complete_year_dates.forEach (date) ->
                                    mycount = 0  # iniciamos contador
                                    if date not in (x.date for x in items)
                                        datos.push mycount
                                    else
                                        doc = items.filter((item) -> item.date is date)[0]
                                        if doc.basic_counts[brand]?
                                            words = doc.basic_counts[brand].words
                                            words = ([key, value] for key, value of words)
                                            words.forEach (word) -> 
                                                if word[0] in alias_list[0]['alias'] then mycount += word[1]
                                            datos.push mycount
                                        else
                                            datos.push 0


                                # Añadimos serie de la marca al array global de series
                                # -----------------------------------------------------
                                series.push {
                                    label: brand,
                                    borderColor: brand_colors[brand].borderColor,
                                    backgroundColor: brand_colors[brand].backgroundColor,
                                    borderWidth: 2,
                                    tension: 0,
                                    radius: 0,
                                    data: datos}

                            # Generamos serie en formato chartjs
                            # ----------------------------------
                            data = {
                                labels: complete_year_dates_names,
                                datasets : series
                            }

                            # Devolvemos resultado
                            # ---------------------
                            res.json {results: data}
                        else
                            res.json {error: err}
            else
                res.json {error: err}


    # ---------------------------------------------------------------------------------
    # MODIFICA el campo 'tourist' de una entrada de la colección de tweets clasificados 
    # ---------------------------------------------------------------------------------
    router.get '/entries/month/:month/brand/:brand/id/:id/tourist/:tourist/category/:category/canonical_name/:canonical_name', (req, res) ->
        month = req.params.month
        brand = req.params.brand
        tweet_id_str = req.params.id
        isTourist = req.params.tourist
        category = req.params.category
        canonical_name = req.params.canonical_name
        touristBool = (isTourist =='true') ? true : false

        month = /^(\d\d)-(\d\d)/.exec(req.params.month)[2]

        year = '20' + /^(\d\d)-\d\d/.exec(req.params.month)[1]  # se supone que el año es el mismo en start_date y end_date, chequeado por la parte cliente

        col_name = 'twitter_monthly_viral_tweets_<year>_<brand>'.replace('<year>', year).replace('<brand>', brand)

        query = {}
        query['tweet_id_str'] = tweet_id_str
        query["month"] = year + "-" + month

        if (touristBool)
            newValue = {$set: {touristic: touristBool, category: category, canonical_name: canonical_name}}
            config.mongo_cols[col_name].updateOne query, newValue, (err, result) ->
                if not err
                    res.json {results: 'OK!'}
                else
                    res.json {error: err}
        else
            newValue = {$set: {touristic: touristBool}}
            aggregationStage = {$unset: [ "category", "canonical_name" ] }
            config.mongo_cols[col_name].updateOne query, newValue, aggregationStage, (err, result) ->
                if not err
                    res.json {results: 'OK!'}
                else
                    res.json {error: err}


    router

module.exports = create_router
