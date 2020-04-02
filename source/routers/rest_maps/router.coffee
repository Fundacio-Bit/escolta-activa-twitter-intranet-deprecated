fs = require 'fs'
express = require 'express'
moment = require 'moment'

# =========================================================================
# REST API router to obtain map coordinates
# =========================================================================

create_router = (config) ->

    router = express.Router()

    g_brands = config.brand_list
    g_influencers_categories = config.dictionary_influencers_categories
    fichero = config.context.dictionary_influencers_json

    # -------------------------------------
    # List REST methods of the router
    # -------------------------------------
    router.get '/', (req, res) ->
        path_list = ('/rest_maps' + x.route.path for x in router.stack when x.route?)
        res.json {rest_methods: path_list}

    # ---------------------------------------------
    # GET coordinates filtered by brand and month
    # ---------------------------------------------
    router.get '/coordinates/yearmonth/:yearmonth/brand/:brand', (req, res) ->
        year = req.params.yearmonth.split("-")[0]
        col_name = 'twitter_daily_advanced_counts_<year>'.replace '<year>', year
        query = {}
        projection = {}
        query['date'] = new RegExp('^'+ req.params.yearmonth)
        projection['coordinates.' + req.params.brand] = 1
        projection['_id'] = 0
        all_coordinates = []
        config.mongo_cols[col_name].find(query, projection).each (err, item) ->
            if not err               
                # Append all results to the all_coordinates Array 
                if item != null                   
                    all_coordinates.push.apply(all_coordinates, item.coordinates[req.params.brand])
                # Remove duplicates from all_coordinates and format properly the result once the
                # cursor is exhausted
                else
                    unique_coordinates = all_coordinates.filter((v, i, a) => a.indexOf(v) is i)
                    formatted_coordinates = unique_coordinates.map (x) ->{
                        coordinates: x.slice(1,-1).split(",").map(Number),
                        markerOffset: "",
                        name: ""
                        }
                    res.json { items:  formatted_coordinates }
            else
                res.json {error: err}

    router

module.exports = create_router
