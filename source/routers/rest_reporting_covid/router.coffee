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

    g_brands = config.brand_list
    g_categories = {patrimoni: 'Patrimoni', platges:'Platges', naturalesa:'Naturalesa', esports:'Actividades esportivas', toponims:'Toponims/Zones', esdeveniments:'Esdeveniments'}
    # g_categories_influencers = {esport_cultura:'Esport i cultura', xarxes_socials:'Xarxes socials', comunicacio:'Comunicació', turisme_oci:'Turisme i oci', altres_sectors:'Altres sectors'}
    g_categories_influencers = { turisme_oci:'Turisme i oci', altres_sectors:'Altres sectors', descartats:'Descartats'}
    g_languages = {'es':'Castellà', 'ca':'Català', 'en':'Anglès', 'de':'Alemany', 'other':'Altres', 'total':'Total'}


    utils = require './_utils_files_avail'

    output_dir = config.context.output_base_dir + "twitter/tourism/"
    zip_dir = output_dir + "zip/"
    get_zip_files = utils.get_zip_files(zip_dir)

    year_list = []
    current_year = new Date().getFullYear()
    year_list.push (current_year--).toString() until current_year < 2016  # recoge listado de años tomando 2016 como año inicial


    # -------------------------------------
    # Lista de métodos REST de este router
    # -------------------------------------
    router.get '/', (req, res) ->
        path_list = ('/rest_reporting_covid' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}

    # -------------------------------------------------------------------------------------------------------
    # EXTRAE listado de reports de Twitter disponibles de un año concreto (se usa para refrescar con jQuery).
    # Chequea el estado en que se encuentra cada report, y si existe un ZIP generado para cada uno.
    # -------------------------------------------------------------------------------------------------------
    router.get '/reports/twitter/year/:year', (req, res) ->
        year = req.params.year
        zips = utils.get_zip_files(zip_dir)  # sacamos los paths de los zip's que existen actualment
        res.json {results: zips}

    # ------------------------------------------------
    # EXTRAE report ZIP de Twitter de un mes concreto
    # ------------------------------------------------
    router.get '/reports/twitter/zip/date/:date', (req, res) ->
        date = req.params.date
        if not /^\d\d\d\d-\d\d-\d\d$/.test(date) then return res.json {error: "Format de 'date' invàlid. Format vàlid: 'YYYY-MM-DD'."}

        zips = utils.get_zip_files(zip_dir)  # sacamos los paths de los zip's que existen actualmente
        re = /([12]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))/
        for filename in zips
            if(filename.match(re)[0] == date)
                zip_file = zip_dir + filename
                file = fs.createReadStream zip_file
                stat = fs.statSync zip_file
                res.setHeader('Content-Length', stat.size)
                res.setHeader('Content-Type', 'application/zip')
                res.setHeader('Content-Disposition', "attachment; filename=#{filename}")
                file.pipe(res)

    # # --------------------------------------------
    # # GENERATE monthly and cumulative CSVs and ZIP
    # # --------------------------------------------
    # router.get '/reports/twitter/generate/zip/date/:date', (req, res) ->
    #     date = req.params.date
    #     if not /^\d\d\d\d-\d\d-\d\d$/.test(date) then return res.json {error: "Format de 'date' invàlid. Format vàlid: 'YYYY-MM-DD'."}

    #     if !fs.existsSync(output_dir)
    #         fs.mkdirSync output_dir
    #     if !fs.existsSync(output_dir + 'zip')
    #         fs.mkdirSync output_dir + 'zip'

    #     output_path = zip_dir + 'escolta_activa_twitter_covid_tourism_' + date + '.zip'
    
    #     zip_directory_contents = (source, output_path) ->
    #         archive = archiver('zip', { zlib: { level: 9 }})
    #         stream = fs.createWriteStream(output_dir);

    #         archive.directory(source, false)
    #             .on('error', (err) -> reject({error: err}))
    #             .pipe(stream)

    #         stream.on('close', () -> return({message: "The ZIP has been created"}))
    #         archive.finalize()


    #     return zip_directory_contents(output_dir, output_path)


    router

module.exports = create_router