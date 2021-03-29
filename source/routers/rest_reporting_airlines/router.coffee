fs = require 'fs'
express = require 'express'
bodyParser = require 'body-parser'
MongoClient = require('mongodb').MongoClient
moment = require 'moment'
archiver = require 'archiver'
path = require 'path'

# =====================================================
# REST API para la extracción y generación de Reports.
# =====================================================

create_router = (config) ->

    router = express.Router()
    router.use( bodyParser.json() )  # to support JSON-encoded bodies

    # g_brands = config.brand_list
    # g_categories = {patrimoni: 'Patrimoni', platges:'Platges', naturalesa:'Naturalesa', esports:'Actividades esportivas', toponims:'Toponims/Zones', esdeveniments:'Esdeveniments'}
    # g_categories_influencers = { turisme_oci:'Turisme i oci', altres_sectors:'Altres sectors', descartats:'Descartats'}
    # g_languages = {'es':'Castellà', 'ca':'Català', 'en':'Anglès', 'de':'Alemany', 'other':'Altres', 'total':'Total'}


    utils = require './_utils_files_avail'

    current_year = new Date().getFullYear()

    base_dir = config.context.twitter.csv_base_dir + 'extraction_1/sector_aeri/'
    csv_dir = base_dir + current_year + "/"
    get_csv_files = utils.get_files(csv_dir)

    year_list = []
    year_list.push (current_year--).toString() until current_year < 2016  # recoge listado de años tomando 2016 como año inicial

    # -------------------------------------
    # Lista de métodos REST de este router
    # -------------------------------------
    router.get '/', (req, res) ->
        path_list = ('/rest_reporting_airlines' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}

    # -------------------------------------------------------------------------------------------------------
    # EXTRAE listado de reports de Twitter disponibles de un año concreto (se usa para refrescar con jQuery).
    # Chequea el estado en que se encuentra cada report, y si existe un ZIP generado para cada uno.
    # -------------------------------------------------------------------------------------------------------
    router.get '/reports/twitter/year/:year', (req, res) ->
        year = req.params.year
        files = utils.get_files(csv_dir)  # sacamos los paths de los zip's que existen actualment
        res.json {results: files}

    # ------------------------------------------------
    # EXTRAE report csv de Twitter de un mes concreto
    # ------------------------------------------------
    router.get '/reports/twitter/csv/date/:date', (req, res) ->
        date = req.params.date
        if not /^\d\d\d\d-\d\d-\d\d$/.test(date) then return res.json {error: "Format de 'date' invàlid. Format vàlid: 'YYYY-MM-DD'."}

        files = utils.get_files(csv_dir)  # sacamos los paths de los zip's que existen actualmente
        re = /([12]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))/
        for filename in files
            if(filename.match(re)[0] == date)
                csv_file = csv_dir + filename
                file = fs.createReadStream csv_file
                stat = fs.statSync csv_file
                res.setHeader('Content-Length', stat.size)
                res.setHeader('Content-Type', 'text/csv')
                res.setHeader('Content-Disposition', "attachment; filename=#{filename}")
                file.pipe(res)

    router

module.exports = create_router