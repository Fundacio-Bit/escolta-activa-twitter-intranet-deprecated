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

    get_zip_files = utils.get_zip_files(config.context.output_base_dir)

    year_list = []
    current_year = new Date().getFullYear()
    year_list.push (current_year--).toString() until current_year < 2016  # recoge listado de años tomando 2016 como año inicial


    # -------------------------------------
    # Lista de métodos REST de este router
    # -------------------------------------
    router.get '/', (req, res) ->
        path_list = ('/rest_reporting' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}

    # -------------------------------------------------------------------------------------------------------
    # EXTRAE listado de reports de Twitter disponibles de un año concreto (se usa para refrescar con jQuery).
    # Chequea el estado en que se encuentra cada report, y si existe un ZIP generado para cada uno.
    # -------------------------------------------------------------------------------------------------------
    router.get '/reports/twitter/year/:year', (req, res) ->
        year = req.params.year
        if year not in year_list
            return res.json {error: "Any no disponible a MongoDB: #{year}"}

        # Preparamos query y projection
        # ------------------------------
        myregex = new RegExp('^'+year)
        query = {'header.month': myregex}
        projection = {_id: 0, header: 1, notes: 1, sections: 1, links: 1}
        collection_name = 'twitter_monthly_json_reports_<year>'.replace '<year>', year
        config.mongo_cols[collection_name].find(query, projection).sort({'header.month': -1}).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen dades per l'any indicat: <strong>#{req.params.year}</strong> a la colleció " + collection_name}
                else
                    zips = utils.get_zip_files(config.context.output_base_dir)  # sacamos los paths de los zip's que existen actualment

                    months = items.map (item) ->
                        month: item.header.month
                        links: item.links
                        tweet_counts: item.sections.tweet_counts
                        language_counts: item.sections.language_counts
                        zip_exists: if item.header.month in (x for x of zips) then true else false
                        zip_status:
                            is_ready_to_generate: if item.header.zip_generation.status is 'READY_TO_GENERATE' then true else false
                            is_generating: if item.header.zip_generation.status is 'GENERATING' then true else false
                            timestamp: if item.header.zip_generation.timestamp? then item.header.zip_generation.timestamp else null
                            error_message: if item.header.zip_generation.error_message? then item.header.zip_generation.error_message else ''

                    # En caso de 'GENERATING' calculamos el porcentaje de compleción
                    # ---------------------------------------------------------------
                    estimated_seconds_to_generate_zip = 140   # tiempo estimado de generación del zip
                    months.forEach (month) ->
                        if month.zip_status.timestamp?
                            current_moment = Math.round(new Date().getTime()/1000)
                            month.zip_status.percent_completion = Math.round ((current_moment - month.zip_status.timestamp)/estimated_seconds_to_generate_zip)*100

                        if month.zip_status.percent_completion > 100 then month.zip_status.percent_completion = 100

                    res.json {results: months}
            else
                res.json {error: err}

    # ----------------------------------------------------------------------------------------------------
    # EXTRAE los datos de las diferentes secciones del informe y devuelve un CSV con Tweet counts y Language counts
    # ----------------------------------------------------------------------------------------------------
    router.get '/reports/twitter/csv/json/:section/yearmonth/:yearmonth/csv', (req, res) ->

        yearmonth = req.params.yearmonth
        if not /^\d\d\d\d-\d\d$/.test(yearmonth) then return res.json {error: "Format de 'yearmonth' invàlid. Format vàlid: 'YYYY-MM'."}

        year = yearmonth.split('-')[0]
        if year not in year_list
            return res.json {error: "Any no disponible a MongoDB: #{year}"}

        section = req.params.section
        valid_sections = ['tweet_counts', 'language_counts']
        if section not in valid_sections then return res.json {error: "Valor de 'section' desconegut. Valors vàlids: #{JSON.stringify valid_sections}"}

        # Preparamos query y projection
        # ------------------------------
        query = {'header.month': yearmonth}

        projection = {_id: 0, "sections.#{section}": 1}
        collection_name = 'twitter_monthly_json_reports_<year>'.replace '<year>', year
        config.mongo_cols[collection_name].find(query, projection).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen dades per el 'yearmonth' indicat: <strong>#{yearmonth}</strong>"}
                else
                    # res.json {results: items[0].sections[section]}

                    data = items[0].sections[section]

                    # Creamos un fichero CSV con las palabras
                    # ----------------------------------------
                    rows_csv = []
                    if section is 'tweet_counts'
                        rows_csv.push "\"marca\",\"total\",\"variació\""  # header
                        g_brands.forEach (brand) ->
                            rows_csv.push "\"#{brand}\",\"#{data.total[brand]}\",\"#{data.variation[brand]}\""
                        csv = rows_csv.join('\n')
                        res.writeHead(200, {'Content-Type': 'application/force-download','Content-disposition':"attachment; filename=twitter-tweet-counts-#{req.params.yearmonth}.csv"})
                        res.end csv
                    else if section is 'language_counts'
                        header = "\"idioma\","
                        g_brands.forEach (brand) ->
                            header = header.concat "\"#{brand}\","
                        header = header.concat "\"Total\",\"%Total\""
                        rows_csv.push header
                        for key of g_languages
                            row = "\"#{g_languages[key]}\","
                            g_brands.forEach (brand) ->
                                row= row.concat "\"#{data[brand][key]}\","
                            row= row.concat "\"#{data['per_lang'][key].count}\","
                            row= row.concat "\"#{data['per_lang'][key].percent}\""
                            rows_csv.push row
                        csv = rows_csv.join('\n')
                        res.writeHead(200, {'Content-Type': 'application/force-download','Content-disposition':"attachment; filename=twitter-languages-counts-#{req.params.yearmonth}.csv"})
                        res.end csv
            else
                res.json {error: err}

    # ------------------------------------------------
    # EXTRAE report ZIP de Twitter de un mes concreto
    # ------------------------------------------------
    router.get '/reports/twitter/zip/yearmonth/:yearmonth', (req, res) ->
        yearmonth = req.params.yearmonth
        if not /^\d\d\d\d-\d\d$/.test(yearmonth) then return res.json {error: "Format de 'yearmonth' invàlid. Format vàlid: 'YYYY-MM'."}

        zips = utils.get_zip_files(config.context.output_base_dir)  # sacamos los paths de los zip's que existen actualmente
        if yearmonth in (x for x of zips)
            file = fs.createReadStream zips[yearmonth]
            stat = fs.statSync zips[yearmonth]
            res.setHeader('Content-Length', stat.size)
            res.setHeader('Content-Type', 'application/zip')
            res.setHeader('Content-Disposition', "attachment; filename=escolta_activa_#{yearmonth}.zip")
            file.pipe(res)
        else
            res.json {error: "No existeix l'arxiu zip pel 'yearmonth': #{yearmonth}"}


    # --------------------------------------------
    # GENERATE monthly and cumulative CSVs and ZIP
    # --------------------------------------------
    router.get '/reports/twitter/generate/zip/yearmonth/:yearmonth', (req, res) ->
        yearmonth = req.params.yearmonth
        if not /^20\d\d-\d\d$/.test(yearmonth) then return res.json {error: "Format de 'yearmonth' invàlid. Format vàlid: 'YYYY-MM'.L'any ha de començar amb 20."}

        year = yearmonth.split('-')[0]
        month = yearmonth.split('-')[1]
        months_so_far = []
        i = 1
        while i <= parseInt(month)
            if i <=9
                months_so_far.push(year + '-0' + i)
            else
                months_so_far.push(year + '-' + i)
            i++

        if year not in year_list
            return res.json {error: "Any no disponible a MongoDB: #{year}"}

        output_dir = config.context.output_base_dir + "twitter/monthly/#{yearmonth}/"
        if !fs.existsSync(output_dir)
            fs.mkdirSync output_dir
        if !fs.existsSync(output_dir + 'zip')
            fs.mkdirSync output_dir + 'zip'
        if !fs.existsSync(output_dir + 'csvs')
            fs.mkdirSync output_dir + 'csvs'
        if !fs.existsSync(output_dir + 'csvs/cumulative')
            fs.mkdirSync output_dir + 'csvs/cumulative'

        ###*
        * Outputs total viral tweets for each brand for a whole year
        * @returns {Promise}
        ###       
        get_viral_tweets_by_brand = (brand, v_tweets_array) ->
            return new Promise (resolve, reject) ->
                # Prepare query and projection
                # -----------------------------
                query = { month: {$in: months_so_far} , touristic: true }
                projection = { _id: 0 }
                collection_name = 'twitter_monthly_viral_tweets_<year>_<brand>'.replace('<year>', year).replace('<brand>', brand)
                config.mongo_cols[collection_name].find(query, projection).toArray (err, items) ->
                    if not err
                        if items.length is 0
                            reject {error: "No existeixen dades per l'any indicat: <strong>#{year}</strong>"}
                        else
                            ## Add brand to items
                            items.forEach (tweet) ->
                                tweet['brand'] = brand
                            resolve v_tweets_array.concat(items)
                    else
                        reject {error: err}


        ###*
        * @returns {Promise}
        ###
        add_viral_touristic_counts_and_percent_by_brand = (viral_tweets_array) ->
            return new Promise (resolve, reject) ->

                # Define the function that will process data for both, cumulative and monthly CSVs
                process_data = (total_data, viral_data) ->
                    total_tweet_counts = {}
                    counts_table = []
                    g_brands.forEach (brand) ->
                        total_tweet_counts[brand] = 0
                        # Get total cummulative tweet counts for each brand
                        if total_data.length is 0
                            counts_table.push([brand, 0, 0, '-%'])
                        else
                            tweets_by_brand_array = total_data.map ( (item) -> item.basic_counts[brand].tweets )
                            total_tweet_counts[brand] = tweets_by_brand_array.reduce ( (a, b) -> return a + b )
                            # Generate csv row for a brand
                            viral_touristic_tweets_by_brand_array = viral_data.filter ( (item) -> item.brand is brand )
                            # console.log('viral_touristic_tweets_by_brand_array.length: ' + viral_touristic_tweets_by_brand_array.length)
                            if viral_touristic_tweets_by_brand_array.length is 0
                                console.log("No existeixen viral tweets per brand #{brand} and any <strong>#{year}</strong>")
                                return null

                            viral_touristic_counts_by_brand_array = viral_touristic_tweets_by_brand_array.map ( (tweet) -> tweet.count )
                            viral_touristic_counts_by_brand = viral_touristic_counts_by_brand_array.reduce ( (a, b) -> return a + b )
                            
                            percent = ( viral_touristic_counts_by_brand * 100 ) / total_tweet_counts[brand]
                            
                            counts_table.push([brand, total_tweet_counts[brand], viral_touristic_counts_by_brand, percent.toFixed(2) + '%'])
                    return counts_table

                # Prepare query and projection
                # -----------------------------
                query = {}
                projection = { _id: 0, date: 1 }
                g_brands.forEach (brand) ->
                    proj_route =  "basic_counts." + brand + ".tweets"
                    projection[proj_route] =  1
                collection_name = 'twitter_daily_basic_counts_<year>'.replace '<year>', year

                config.mongo_cols[collection_name].find(query, projection).toArray (err, items) ->
                    if not err
                        if items.length is 0
                            reject {error: "No existeixen dades per l'any indicat: <strong>#{year}</strong>"}
                        else
                            ## CUMULATIVE CSVs ##
                            # Get total_count items from the year beginning to the yearmonth being processed (included)
                            cum_items = items.filter ( (item) -> months_so_far.join().indexOf('-' + item.date.split('-')[1]) != -1)

                            # Get cumulative CSV.
                            # The viral tweets_array has been filtered previously up to the yearmonth being processed. Therefore, it can be
                            # used without additional filtering.
                            cum_brands_counts_table = process_data(cum_items, viral_tweets_array)
                            try
                                create_csv(output_dir + 'csvs/cumulative/brands_counts_cumulative.csv', cum_brands_counts_table)
                                # resolve viral_tweets_array
                            catch e
                                reject {error: e}


                            ## MONTHLY CSV ##
                            # Get total_counts items from the yearmonth being processed                 
                            month_items = items.filter ( (item) -> item.date.indexOf(yearmonth) != -1 )

                            month_viral_tweets_array = viral_tweets_array.filter ( (item) -> item.month is yearmonth)

                            # Get monthly CSV.
                            month_brands_counts_table = process_data(month_items, month_viral_tweets_array)
                            if month_brands_counts_table.length < g_brands.length
                                err = "Fins que no seleccioni els tuits virals no es pot generar el fitxer zip."
                                reject {error: err}
                            else
                                try
                                    create_csv(output_dir + 'csvs/brands_counts.csv', month_brands_counts_table)
                                    resolve viral_tweets_array
                                catch e
                                    reject {error: e}
                    else
                        reject {error: err}


        ###*
        * @returns {Promise}
        ###
        add_cumulative_viral_touristic_series_by_brand = (viral_tweets_array) ->
            return new Promise (resolve, reject) ->
                brands_series_table = []
                months_row = []
                i = 1
                while i <= 12
                    if i <=9
                        months_row.push(year + '-0' + i)
                    else
                        months_row.push(year + '-' + i)
                    i++

                brands_series_table.push([''].concat(months_row))

                g_brands.forEach (brand) ->

                    brand_series_row = [brand]
                    # Get cumulative time series of viral monthly aggregated counts
                    viral_touristic_tweets_by_brand_array = viral_tweets_array.filter ( (item) -> item.brand is brand )
                    months_row.forEach (month) ->
                        viral_touristic_tweets_brand_month_array = viral_touristic_tweets_by_brand_array.filter ( (item) -> item.month is month )
                        if viral_touristic_tweets_brand_month_array.length > 0
                            viral_touristic_counts_brand_month_array = viral_touristic_tweets_brand_month_array.map ( (item) -> item.count )
                            viral_touristic_counts_brand_month = viral_touristic_counts_brand_month_array.reduce (a, b) ->
                                        return a + b
                            brand_series_row.push(viral_touristic_counts_brand_month)
                        else
                            brand_series_row.push(0)
                    
                    brands_series_table.push(brand_series_row)

                # Save to CSV
                try
                    create_csv(output_dir + 'csvs/cumulative/brands_series.csv', brands_series_table)
                    resolve viral_tweets_array
                catch e
                    reject {error: e}

        ###*
        * @returns {Promise}
        ###
        add_cumulative_viral_touristic_series_by_brand_and_category = (viral_tweets_array) ->
            return new Promise (resolve, reject) ->
                g_categories['genèric'] = 'Altres'

                for g_category_key of g_categories
                    brands_cat_series_table = []
                    months_row = []
                    i = 1
                    while i <= 12
                        if i <=9
                            months_row.push(year + '-0' + i)
                        else
                            months_row.push(year + '-' + i)
                        i++

                    brands_cat_series_table.push([g_category_key].concat(months_row))

                    g_brands.forEach (brand) ->

                        brand_cat_series_row = [brand]
                        # Get annual time series of viral monthly aggregated counts
                        viral_touristic_tweets_brand_cat_array = viral_tweets_array.filter ( (item) -> item.brand is brand and item.category is g_category_key)
                        months_row.forEach (month) ->
                            viral_touristic_tweets_brand_cat_month_array = viral_touristic_tweets_brand_cat_array.filter ( (item) -> item.month is month )
                            if viral_touristic_tweets_brand_cat_month_array.length > 0
                                viral_touristic_counts_brand_cat_month_array = viral_touristic_tweets_brand_cat_month_array.map ( (item) -> item.count )

                                viral_touristic_counts_brand_cat_month = viral_touristic_counts_brand_cat_month_array.reduce (a, b) ->
                                            return a + b
                                brand_cat_series_row.push(viral_touristic_counts_brand_cat_month)
                            else
                                brand_cat_series_row.push(0)
                        
                        brands_cat_series_table.push(brand_cat_series_row)

                    # Save to CSV
                    try
                        create_csv(output_dir + 'csvs/cumulative/brands_cat_series_' + g_category_key + '.csv', brands_cat_series_table)
                        resolve viral_tweets_array
                    catch e
                        reject {error: e}


        ###*
        * 
        * @returns {Promise}
        ###
        get_brand_lang_tables = (viral_tweets_array) ->
            return new Promise (resolve, reject) ->

                process_data = (viral_data) ->
                    brand_lang_table = []

                    # Add a header row
                    header = ["idioma"]
                    g_brands.forEach (brand) ->
                        header.push(brand)
                    header.push.apply(header, ["Total","%Total"])
                    brand_lang_table.push(header)

                    # Add brand + lang counts and get brand total and absolute total count
                    absolute_total_count = 0

                    # Create a brand total counts filled with zeroes
                    brand_total_counts = ['Total']
                    i = 0
                    while i < g_brands.length
                        brand_total_counts.push 0
                        i++

                    for lang_iso_code, lang_name of g_languages
                        if lang_name != 'Total'
                            row_string = [lang_name]
                            
                            row_position_index = 1
                            g_brands.forEach (brand) ->                                    
                                counts_by_brand_and_lang = 0
                                if lang_name != 'Altres'                                    
                                    tweets_by_brand_and_lang_array = viral_data.filter ( (item) -> item.brand is brand && item.tweet_lang is lang_iso_code)
                                else
                                    tweets_by_brand_and_lang_array = viral_data.filter ( (item) -> item.brand is brand && ['es', 'ca', 'en', 'de'].indexOf(item.tweet_lang) == -1)
                                counts_by_brand_and_lang_array = tweets_by_brand_and_lang_array.map ( (tweet) -> tweet.count)                                    
                                if counts_by_brand_and_lang_array.length > 0
                                    counts_by_brand_and_lang = counts_by_brand_and_lang_array.reduce (a, b) ->
                                        return a + b                                    
                                row_string.push(counts_by_brand_and_lang)
                                
                                brand_total_counts[row_position_index] += counts_by_brand_and_lang
                                absolute_total_count += counts_by_brand_and_lang
                                row_position_index +=1 
                            brand_lang_table.push(row_string)

                    # Add row totals and percent
                    brand_lang_table.slice(1).forEach (brand_lang_row) ->
                        row_total = brand_lang_row.slice(1).reduce (a, b) -> return a + b  
                        brand_lang_row.push(row_total)
                        brand_lang_row.push((row_total * 100 / absolute_total_count).toFixed(2) + '%')

                    # Add column totals and percent
                    last_row_total = brand_total_counts.slice(1).reduce (a, b) -> return a + b
                    brand_total_counts.push(last_row_total)
                    brand_total_counts.push((last_row_total * 100 / absolute_total_count).toFixed(2) + '%')

                    brand_lang_table.push(brand_total_counts)
                    return brand_lang_table

                ## CUMULATIVE CSV ##
                cumulative_data_table = process_data(viral_tweets_array)
                try
                    create_csv(output_dir + 'csvs/cumulative/brands_langs_counts_cumulative.csv', cumulative_data_table)

                catch e
                    reject {error: e}

                ## MONTHLY CSV ##
                month_viral_tweets_array = viral_tweets_array.filter ( (item) -> item.month is yearmonth)
                month_data_table = process_data(month_viral_tweets_array)                
                try
                    create_csv(output_dir + 'csvs/brands_langs_counts.csv', month_data_table)
                    resolve viral_tweets_array
                catch e
                    reject {error: e}            

        ###*
        * 
        * @returns {Promise}
        ###
        get_brand_cat_lang_tables = (viral_tweets_array) ->
            return new Promise (resolve, reject) ->

                process_data = (viral_data) ->
                    brand_cat_lang_table = []

                    g_brands.forEach (brand) ->
                        # Add a header row per brand
                        brand_header = [brand]
                        brand_header.push.apply(brand_header, Object.values(g_languages))
                        brand_cat_lang_table.push(brand_header)

                        g_categories['genèric'] = 'Altres'

                        for g_category_key of g_categories
                            row_string = [g_category_key] 
                            for lang_iso_code, lang_name of g_languages                                       
                                if lang_name != 'Total'
                                    # row_position_index = 1

                                    counts_by_brand_cat_lang = 0
                                    if lang_name != 'Altres'                                    
                                        tweets_by_brand_cat_lang_array = viral_data.filter ( (item) -> item.brand is brand && item.tweet_lang is lang_iso_code && item.category is g_category_key)
                                    else
                                        tweets_by_brand_cat_lang_array = viral_data.filter ( (item) -> item.brand is brand && ['es', 'ca', 'en', 'de'].indexOf(item.tweet_lang) == -1 && item.category is g_category_key)
                                    counts_by_brand_cat_lang_array = tweets_by_brand_cat_lang_array.map ( (tweet) -> tweet.count)                                    
                                    if counts_by_brand_cat_lang_array.length > 0
                                        counts_by_brand_cat_lang = counts_by_brand_cat_lang_array.reduce (a, b) ->
                                            return a + b                                    
                                    row_string.push(counts_by_brand_cat_lang)

                            row_total = row_string.slice(1).reduce (a, b) -> return a + b
                            row_string.push(row_total)
                            brand_cat_lang_table.push(row_string)
                        
                        brand_cat_lang_table.push([])
                    return brand_cat_lang_table

                ## CUMULATIVE CSV ##
                cumulative_data_table = process_data(viral_tweets_array)
                try
                    create_csv(output_dir + 'csvs/cumulative/brands_cats_langs_counts_cumulative.csv', cumulative_data_table)

                catch e
                    reject {error: e}

                ## MONTHLY CSV ##
                month_viral_tweets_array = viral_tweets_array.filter ( (item) -> item.month is yearmonth)
                month_data_table = process_data(month_viral_tweets_array)
                try
                    create_csv(output_dir + 'csvs/brands_cats_langs_counts.csv', month_data_table)
                    resolve viral_tweets_array
                catch e
                    reject {error: e}     

        ###*
        * 
        * @returns {Promise}
        ###
        get_rankings_tables = (viral_tweets_array) ->
            return new Promise (resolve, reject) ->

                process_data = (viral_data) ->
                    aggregated_viral_tweets = {}
                    aggregated_viral_tweets_array = []
                    g_brands.forEach (brand) ->
                        viral_tweets_array_by_brand = viral_data.filter ( (item) -> item.brand is brand)

                        viral_tweets_simplified = viral_tweets_array_by_brand.map ((tweet) -> 
                            {'_id': tweet.category + '$-$' + tweet.canonical_name,
                            'count': tweet.count}
                        )

                        aggregated_viral_tweets = viral_tweets_simplified.reduce (accumulator, currentValue) ->
                            if currentValue._id not of accumulator
                                accumulator[currentValue._id] = currentValue.count
                            else
                                accumulator[currentValue._id] += currentValue.count
                            accumulator
                        , {}

                        for key_id, total of aggregated_viral_tweets
                            category = key_id.split('$-$')[0]
                            canonical_name = key_id.split('$-$')[1]

                            aggregated_viral_tweets_array.push({'_id': {'brand': brand, 'category': category, 'canonical_name': canonical_name}, 'total': total})

                    aggregated_viral_tweets_array.sort (a, b) -> if a.total < b.total then 1 else -1
                        
                    # Create the rankings per brand table
                    rankings_per_brand_table = []
                    g_brands.forEach (brand) ->
                        rankings_per_brand_table.push([brand])
                        aggregated_viral_tweets_array.forEach (item) ->
                            if item._id.brand == brand
                                if item._id.category == 'genèric' and item._id.canonical_name == 'genèric'
                                    rankings_per_brand_table.push(['Altres' + '\t'+ item.total + ' RT'])
                                else if item._id.canonical_name == 'genèric'
                                    rankings_per_brand_table.push([item._id.category[0].toUpperCase() + item._id.category.slice(1) + ' ' + item._id.canonical_name + '\t'+ item.total + ' RT'])
                                else                                
                                    rankings_per_brand_table.push([item._id.canonical_name + '\t'+ item.total + ' RT'])
                        rankings_per_brand_table.push([])
                    
                    # Create the rankings summary table
                    rankings_summary_table = []
                    header = []
                    g_brands.forEach (brand) ->
                        header.push(brand + "\t")
                    rankings_summary_table.push(header)
                    for g_category_key of g_categories
                        rankings_summary_table.push([g_category_key, '','',''])

                        category_matrix = []
                        # Initialize a matrix with an empty column per brand
                        g_brands.forEach (brand) ->
                            category_matrix.push([brand])
                        brand_index = 0
                        g_brands.forEach (brand) -> 
                            aggregated_viral_tweets_array.forEach (item) ->
                                if item._id.brand == brand and item._id.category == g_category_key
                                    category_matrix[brand_index].push([item._id.canonical_name + "\t"+ item.total + ' RT'])
                            brand_index +=1

                        for cat_row_nr in [1...6] by 1
                            row = []
                            category_matrix.forEach (column) ->
                                if column[cat_row_nr]
                                    row.push(column[cat_row_nr])
                                else
                                    row.push([ "_\t"])
                            rankings_summary_table.push(row)
                    return [rankings_per_brand_table, rankings_summary_table]

                ## CUMULATIVE CSV ##
                cumulative_results = process_data(viral_tweets_array)

                try
                    create_csv(output_dir + 'csvs/cumulative/rankings_per_brand_cumulative.csv', cumulative_results[0])
                    create_csv(output_dir + 'csvs/cumulative/rankings_summary_cumulative.csv', cumulative_results[1])

                catch e
                    reject {error: e}

                ## MONTHLY CSV ##
                month_viral_tweets_array = viral_tweets_array.filter ( (item) -> item.month is yearmonth)
                month_results = process_data(month_viral_tweets_array)
                try
                    create_csv(output_dir + 'csvs/rankings_per_brand.csv', month_results[0])
                    create_csv(output_dir + 'csvs/rankings_summary.csv', month_results[1])
                    resolve viral_tweets_array
                catch e
                    reject {error: e}    


        ###*
        * 
        * @returns {Promise}
        ###
        get_influencers_tables = (viral_tweets_array) ->
            return new Promise (resolve, reject) ->

                process_data = (viral_data, discarded) ->
                    aggregated_viral_tweets = {}
                    aggregated_viral_tweets_array = []
                    g_brands.forEach (brand) ->
                        viral_tweets_array_by_brand = viral_data.filter ( (item) -> item.brand is brand)

                        viral_tweets_simplified = viral_tweets_array_by_brand.map ((tweet) -> 
                            {'_id': tweet.user_screen_name, 'count': tweet.count}
                        )

                        aggregated_viral_tweets = viral_tweets_simplified.reduce (accumulator, currentValue) ->
                            if currentValue._id not of accumulator
                                accumulator[currentValue._id] = currentValue.count
                            else
                                accumulator[currentValue._id] += currentValue.count
                            accumulator
                        , {}

                        for key_id, total of aggregated_viral_tweets
                            aggregated_viral_tweets_array.push({'_id':key_id, 'total': total, 'brand':brand})

                    aggregated_viral_tweets_array.sort (a, b) -> if a.total < b.total then 1 else -1
                        
                    # Create the influencers per brand table
                    influencers_per_brand_table = []
                    g_brands.forEach (brand) ->
                        influencers_per_brand_table.push([brand])
                        aggregated_viral_tweets_array.forEach (item) ->
                            if item.brand == brand and item._id not in discarded
                                influencers_per_brand_table.push([item._id + '\t'+ item.total + ' RT'])
                        influencers_per_brand_table.push([])
                    return influencers_per_brand_table

                # Prepare query and projection to get array of screen_names of discarded influencers
                # -----------------------------------------------------------------------------------
                query = {'category': 'descartats'}
                projection = {'_id': 0, 'influencer': 1}

                collection_name = 'dictionary_influencers'
                config.mongo_cols[collection_name].find(query, projection).toArray (err, items) ->
                    if not err
                        # get aggregated viral tweets removing discarded influencers
                        if items.length is 0
                            discarded_influencers = []
                        else
                            discarded_influencers = items

                        ## CUMULATIVE CSV ##
                        cumulative_data_table = process_data(viral_tweets_array, discarded_influencers)
                        try
                            create_csv(output_dir + 'csvs/cumulative/influencers_per_brand_cumulative.csv', cumulative_data_table)

                        catch e
                            reject {error: e}

                        ## MONTHLY CSV ##
                        month_viral_tweets_array = viral_tweets_array.filter ( (item) -> item.month is yearmonth)
                        month_data_table = process_data(month_viral_tweets_array, discarded_influencers)
                        try
                            create_csv(output_dir + 'csvs/influencers_per_brand.csv', month_data_table)
                            resolve {message: "Success. CSVs Processing finished"}
                        catch e
                            reject {error: e}
                    else
                        reject {error: err}  

        ###*
        * Creates a csv from a set of input rows
        * @param {Array] csv_name   The full path to the output CSV, including the filename
        * @param {Array] rows   The array of rows that will be written in the CSV
        * @returns {Object} Error or success message
        ###
        create_csv = (csv_name, rows) ->

            csv_data = ''
            rows.forEach (row) ->
                csv_data = csv_data.concat(row.join(','))
                csv_data = csv_data.concat('\n')

            fs.writeFile csv_name, csv_data, 'utf8', (err) ->
                if err
                    success_flag = false
                else
                    success_flag = true
                return success_flag

        ###*
        * @param {String} source
        * @param {String} out
        * @returns {Promise}
        ###
        zip_directory_contents = (source, out) ->
            archive = archiver('zip', { zlib: { level: 9 }})
            stream = fs.createWriteStream(out);

            return new Promise (resolve, reject) ->
                archive.directory(source, false)
                .on('error', (err) -> reject({error: err}))
                .pipe(stream)
                
                # console.log(source)

                stream.on('close', () -> resolve({message: "The ZIP has been created"}))
                archive.finalize()


        # Call the promises to create CSVs sequentially. The last step will create the ZIP file.
        get_viral_tweets_by_brand('mallorca', [])
            .then (viral_tweets) ->
                return get_viral_tweets_by_brand('menorca', viral_tweets)
            .then (viral_tweets) ->
                return get_viral_tweets_by_brand('ibiza', viral_tweets)
            .then (viral_tweets) ->
                return get_viral_tweets_by_brand('formentera', viral_tweets)
            .then (viral_tweets) ->
                return add_viral_touristic_counts_and_percent_by_brand(viral_tweets)
            .then (viral_tweets) ->
                return add_cumulative_viral_touristic_series_by_brand(viral_tweets)
            .then (viral_tweets) ->
                return add_cumulative_viral_touristic_series_by_brand_and_category(viral_tweets)
            .then (viral_tweets) ->
                return get_brand_lang_tables(viral_tweets)
            .then (viral_tweets) ->
                return get_brand_cat_lang_tables(viral_tweets)
            .then (viral_tweets) ->
                return get_rankings_tables(viral_tweets)
            .then (viral_tweets) ->
                return get_influencers_tables(viral_tweets)
            .then (result_message) ->
                console.log(result_message)        
            .then () ->
                zip_output_path = output_dir + 'zip/escolta_activa_twitter_' + yearmonth + '.zip'
                return zip_directory_contents(output_dir + 'csvs', zip_output_path)
            .then (result_message) ->
                console.log(result_message)
                res.json {message: result_message}
            .catch (error) ->
                console.error 'failed', error
                res.json {error: error}


    # --------------------------------------------------------------------------------------------------------------
    # EXTRAE tabla de frecuencias de términos agregadas por mes, filtrando por marca y year-month y devuelve un CSV
    # --------------------------------------------------------------------------------------------------------------
    router.get '/reports/twitter/wordcounts/brand/:brand/yearmonth/:yearmonth/csv', (req, res) ->

        # Chequeamos parámetros
        # ----------------------
        if not /^\d\d\d\d-\d\d$/.test(req.params.yearmonth)
            return res.json {error: "ERROR: Format de 'yearmonth' incorrecte. Format vàlid: 'YYYY-MM'."}

        if req.params.brand not in config.brand_list
            return res.json {error: "Valor de 'brand' desconegut. Valors permesos: #{config.brand_list.join ', '}"}

        year = /^(\d\d\d\d)-\d\d$/.exec(req.params.yearmonth)[1]
        col_name = 'twitter_monthly_counts_words_' + year + '_' + req.params.brand

        if col_name not in (x for x of config.mongo_cols)
            return res.json {error: "No existeix la col.lecció <strong>#{col_name}</strong> a MongoDB per l'any "}

        results = []

        # Preparamos query y projection
        # ------------------------------
        query = {date: req.params.yearmonth}
        projection = {}
        projection["_id"] = 0
        projection["date"] = 0

        config.mongo_cols[col_name].find(query, projection).sort({count: -1 }).toArray (err, items) ->
            if not err
                if items.length is 0
                    res.json {error: "No existeixen dades per l'any-mes indicat: <strong>#{req.params.yearmonth}</strong>"}
                else
                    # Creamos un fichero CSV con las palabras
                    # ----------------------------------------
                    rows_csv = []
                    rows_csv.push "\"word\",\"count\""  # header
                    items.forEach (item) -> rows_csv.push "\"#{item.ngram}\",\"#{item.count}\""
                    csv = rows_csv.join('\n')

                    res.writeHead(200, {'Content-Type': 'application/force-download','Content-disposition':"attachment; filename=twitter-#{req.params.brand}-#{req.params.yearmonth}.csv"})
                    res.end csv
            else
                res.json {error: err}
    router

module.exports = create_router