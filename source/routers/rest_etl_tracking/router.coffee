express = require 'express'
mongodb = require 'mongodb'
moment = require 'moment'
moment.locale('ca')

# ============================================================================
# REST API para el seguimiento de datos extraídos (CSV's) y colecciones Mongo
# ============================================================================

config = require '../../../_config'
context_name = config.current_context
context = config.contexts[context_name]

dateUtils = require './utils/_date_utils'
isValidDate = dateUtils.isValidDate

csvUtils = require './utils/get_csv_availability'
getAavailableCSVsByYearMonth = csvUtils.getAavailableCSVsByYearMonth

mongoUtils = require './utils/get_col_availability'
getAavailableMongoDocsByYearMonth = mongoUtils.getAavailableMongoDocsByYearMonth


# NOTA: no se puede devolver una colección con return desde un callback (return collection), da problemas undefined,
# por eso hay que instanciar una variable global (my_collections) desde openMongoConnection.

# Objeto que guardará colecciones a Mongo
# ----------------------------------------
my_collections =
    basic_counts: {}
    advanced_counts: {}

# ------------------------------------
# Función que abre conexión a MongoDB
# ------------------------------------
openMongoConnection = (counts_type, year, mongodb_uri, collection_name) ->
    mongodb.MongoClient.connect mongodb_uri, (error, db) ->
        if not error
            db.collection collection_name, (error, collection) ->
                if not error
                    my_collections[counts_type][year] = collection
                    console.log "[Data Admin] Conectado #{mongodb_uri} (colección = #{collection_name})\n"
                else console.log error
        else console.log 'Error de conexión: ' + error


# Abrimos colecciones de MongoDB
# -------------------------------
year_list = (key for key of context when key.match(/^\d\d\d\d/))
year_list.forEach (year) ->
    openMongoConnection 'basic_counts', year, context.mongodb_uri, context[year]['daily_basic_counts_col']
    openMongoConnection 'advanced_counts', year, context.mongodb_uri, context[year]['daily_advanced_counts_col']


router = express.Router()

# -------------------------------------
# Lista de métodos REST de este router
# -------------------------------------
router.get '/', (req, res) ->
    path_list = ('/rest_data_admin' + x.route.path for x in router.stack when x.route?)
    res.json {rest_methods: path_list}


# -----------------------------------------------------------------------
# CONSULTA disponibilidad de datos en carpetas CSV's y colecciones Mongo
# -----------------------------------------------------------------------
router.get '/availability/year_month/:year_month', (req, res) ->
    if not isValidDate("#{req.params.year_month}-01")
        return res.json {error: "Invalid year_month: #{req.params.year_month}"}

    current_year = /^(\d\d\d\d)-\d\d/.exec(req.params.year_month)[1]

    results = []

    # -------------
    # Group: CSV's
    # -------------
    avail_group = {}
    avail_group['name'] = "Extractors de tweets (CSV's)".toUpperCase()
    avail_group['rows'] = []

    # Row: Nodejs
    # ------------
    row = {}
    row['name'] = "Extractor Nodejs".toUpperCase()
    nodejs_csv_avail = getAavailableCSVsByYearMonth req.params.year_month, 'nodejs'

    if not nodejs_csv_avail.error?
        row['availability'] = nodejs_csv_avail
    else
        return res.json {error: nodejs_csv_avail.error}

    avail_group['rows'].push row

    # Row: Tweepy (ahora conocido como Nody)
    # ---------------------------------------
    row = {}
    row['name'] = "Extractor Nody".toUpperCase()
    tweepy_csv_avail = getAavailableCSVsByYearMonth req.params.year_month, 'tweepy'

    if not tweepy_csv_avail.error?
        row['availability'] = tweepy_csv_avail
    else
        return res.json {error: tweepy_csv_avail.error}

    avail_group['rows'].push row

    results.push avail_group

    # -------------------
    # Group: Mongo cols.
    # -------------------
    avail_group = {}
    avail_group['name'] = "Col·leccions de MongoDB".toUpperCase()
    avail_group['rows'] = []

    # Row: Basic Counts
    # ------------------
    row = {}
    row['name'] = "Agregats Basic_Counts (per dia)".toUpperCase()

    query = {date: {$regex: new RegExp('^'+req.params.year_month)}}
    projection = {_id: 0, date: 1}
    my_collections['basic_counts'][current_year].find(query, projection).sort({date: 1}).toArray (err, items) ->
        if err
            res.json {error: err}
        else
            if items.length is 0
                res.json {error: "No existeixen dades amb els criteris indicats."}
            else
                col_dates = items.map (x) -> x.date
                basic_counts_avail = getAavailableMongoDocsByYearMonth col_dates

                if not basic_counts_avail.error?
                    row['availability'] = basic_counts_avail
                else
                    return res.json {error: basic_counts_avail.error}

                avail_group['rows'].push row


                # Row: Advanced Counts
                # ---------------------
                row = {}
                row['name'] = "Agregats Advanced_Counts (per dia)".toUpperCase()

                query = {date: {$regex: new RegExp('^'+req.params.year_month)}}
                projection = {_id: 0, date: 1}
                my_collections['advanced_counts'][current_year].find(query, projection).sort({date: 1}).toArray (err, items) ->
                    if err
                        res.json {error: err}
                    else
                        if items.length is 0
                            res.json {error: "No existeixen dades amb els criteris indicats."}
                        else
                            col_dates = items.map (x) -> x.date
                            advanced_counts_avail = getAavailableMongoDocsByYearMonth col_dates

                            if not advanced_counts_avail.error?
                                row['availability'] = advanced_counts_avail
                            else
                                return res.json {error: advanced_counts_avail.error}

                            avail_group['rows'].push row


                            results.push avail_group

                            # -------------------------------
                            # devolvemos el resultado global
                            # -------------------------------
                            res.json {results: results, year_month: moment("#{req.params.year_month}-01", 'YYYY-MM-DD').format('MMMM YYYY')}


module.exports = router
