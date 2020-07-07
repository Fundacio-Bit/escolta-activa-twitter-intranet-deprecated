fs = require 'fs'

# Extrae ficheros zip disponibles
# -------------------------------
get_zip_files = (zip_dir) ->
    if !fs.existsSync(zip_dir)
        fs.mkdirSync zip_dir

    return fs.readdirSync zip_dir


module.exports =
    get_zip_files: get_zip_files
