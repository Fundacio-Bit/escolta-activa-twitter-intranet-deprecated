MongoClient = require('mongodb').MongoClient
express = require 'express'
bodyParser = require 'body-parser'
handlebars = require 'express-handlebars'


config = require('./_config')

# ----------------------------------------------------
# Get contexts and brands from MongoDB
# ----------------------------------------------------
mongodb_uri = 'mongodb://localhost:27017/escolta_activa_db'

# Use the Escolta Activa environment variable to get particular contexts of the server
# ------------------------------------------------------------------------------------
my_var = 'ESCOLTA_ACTIVA'
if not process.env[my_var]?
    console.log "\nNo se encuentra la variable de entorno: #{my_var}\n"
    process.exit()
else
    my_context_name = process.env[my_var]

# --------------------------
# Create a config object
# --------------------------
g_db = ''
g_config = {}  

# dicts categories
# -----------------
g_config['dict_terms_cats'] = config.dictionary_terms_categories
g_config['dict_influencers_cats'] = config.dictionary_influencers_categories

# Get context from MongoDB
# ----------------------------
MongoClient.connect mongodb_uri, (err, db) ->
    if not err
        g_db = db
        g_db.collection '_contexts', (err, collection) ->
            if not err
                collection.find({context_name: my_context_name}, {_id: 0}).toArray (err, items) ->
                    if not err
                        if items.length is 0
                            console.log "\nERROR: No se encuentra el contexto con nombre: #{my_context_name}\n"
                        else
                            # Asign context to config
                            # ---------------------------
                            g_config['context'] = items[0]

                            console.log "\n"
                            console.log 'Extraemos context ...'
                            console.log '----------------------'
                            console.log JSON.stringify g_config['context']
                            console.log "\n"
                            get_brands_from_mongo()
                    else
                        console.log err
            else
                console.log err
    else
        console.log err


# Get brands from MongoDB
# ------------------------------
get_brands_from_mongo = ->
    g_db.collection '_brands', (err, collection) ->
        if not err
            collection.find({}, {_id: 0}).toArray (err, items) ->
                if not err
                    # Asign brands array to config
                    # -----------------------------
                    g_config['brand_list'] = (x.brand_name for x in items)
                    console.log "Extraemos brands ..."
                    console.log "---------------------"
                    g_config['brand_list'].forEach (brand, index) -> console.log " [#{index+1}] #{JSON.stringify brand}"
                    console.log "\n"

                    open_mongo_cols()
                else
                    console.log err
        else
            console.log err


# Open Mongo collections
# -----------------------------
open_mongo_cols = ->
    g_config['mongo_cols'] = {}

    console.log "Abrimos colecciones a Mongo ..."
    console.log "--------------------------------"

    # Obtain the name of all connexions of the DB
    # ---------------------------------------------
    g_db.listCollections().toArray (err, cols) ->
        if not err
            col_names = (x.name for x in cols)
            col_names.sort()
            col_names.forEach (col, index) -> console.log " [#{index+1}] #{col}"
            console.log "\n"

            # Open connexion to all collections
            # -----------------------------------------
            index = 0
            openMongoCollection = ->  # recursive function
                g_db.collection col_names[index], (err, collection) ->
                    if not err

                        # Register the open collection in config
                        # -------------------------------------------
                        g_config['mongo_cols'][col_names[index]] = collection

                        # Check if all connexions are open
                        # -----------------------------------------------------
                        if index+1 < col_names.length  # number of not yet open cols...
                            index++
                            openMongoCollection()
                        else
                            console.log " ... conexiones a Mongo abiertas con ÉXITO!\n"

                            # Launch server
                            # --------------------
                            launch_server()
                    else
                        console.log err
                        process.exit()

            # Open conexions
            # ---------------
            openMongoCollection()

        else
            console.log err


# Server launch
# -----------------
launch_server = ->

    app = express()

    # ------------
    # Middlewares
    # ------------
    app.use( bodyParser.json() )  # to support JSON-encoded bodies

    # Paths mapping
    # ---------------
    app.use '/img', express.static 'public/img'
    app.use '/static', express.static 'public/static'
    app.use '/lib/img', express.static 'public/lib/img'
    app.use '/lib/css', express.static 'public/lib/css'
    app.use '/lib/js', express.static 'public/lib/js'
    app.use '/lib/fonts', express.static 'public/lib/fonts'
    app.use '/js', express.static 'public/js'
    app.use '/react-build', express.static 'public/react-build'

    # Router instances
    # ---------------------
    app.use '/rest_tweets_retweets', require('./source/routers/rest_tweets_retweets/router')(g_config)
    app.use '/rest_dictionary_terms', require('./source/routers/rest_dictionary_terms/router')(g_config)
    app.use '/rest_dictionary_influencers', require('./source/routers/rest_dictionary_influencers/router')(g_config)
    app.use '/rest_blacklists', require('./source/routers/rest_blacklists/router')(g_config)
    app.use '/rest_reporting', require('./source/routers/rest_reporting/router')(g_config)
    app.use '/rest_utils', require('./source/routers/rest_utils/router')(g_config)
    app.use '/rest_maps', require('./source/routers/rest_maps/router')(g_config)

    # Template engine Handlebars
    # ---------------------------
    app.engine 'handlebars', handlebars({defaultLayout: 'main'})
    app.set 'view engine', 'handlebars'

    # Routes
    # ------
    app.get '/', (req, res) ->
        res.render 'index'

    app.get '/series/tweets', (req, res) ->
        res.render 'series_tweets'

    app.get '/series/terms', (req, res) ->
        res.render 'series_terms'

    app.get '/series/tweets_filtrats', (req, res) ->
        res.render 'series_tweets_filtrats'

    app.get '/tweets/viral_tweets', (req, res) ->
        res.render 'viral_tweets'

    app.get '/tweets/terms', (req, res) ->
        res.render 'tweets_terms'

    app.get '/tweets/raw', (req, res) ->
        res.render 'tweets_raw'

    app.get '/dictionary/terms', (req, res) ->
        res.render 'dictionary_terms'

    app.get '/dictionary/influencers', (req, res) ->
        res.render 'dictionary_influencers'

    app.get '/maps', (req, res) ->
        res.render 'tweets_map'

    app.get '/reports', (req, res) ->
        res.render 'reports'

    app.get '/report_json_generator', (req, res) ->
        res.render 'report_json_generator'

    # Start server
    # --------------------
    port = process.env.PORT or 5000
    app.listen port, -> console.log "\nArrancamos servidor escuchando en puerto #{port} ...\n"
