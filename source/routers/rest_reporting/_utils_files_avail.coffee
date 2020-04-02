fs = require 'fs'

# Extrae listado disponible de reports PDF de Twitter
# ----------------------------------------------------
get_zip_files = (zip_reports_dir) ->
    zip_dir = zip_reports_dir + 'twitter/monthly/'
    if !fs.existsSync(zip_dir)
        fs.mkdirSync zip_dir

    month_dirs = fs.readdirSync zip_dir

    zip = {}
    month_dirs.forEach (month) ->
        ficheros = fs.readdirSync "#{zip_dir}#{month}/zip"
        if "escolta_activa_twitter_#{month}.zip" in ficheros
            zip[month] = "#{zip_dir}#{month}/zip/escolta_activa_twitter_#{month}.zip"
    return zip


module.exports =
    get_zip_files: get_zip_files
