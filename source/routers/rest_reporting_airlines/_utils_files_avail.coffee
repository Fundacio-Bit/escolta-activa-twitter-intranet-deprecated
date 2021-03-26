fs = require 'fs'

# Extrae ficheros disponibles
# -------------------------------
get_files = (base_dir) ->
    if !fs.existsSync(base_dir)
        fs.mkdirSync base_dir
    return fs.readdirSync base_dir


module.exports =
    get_files: get_files
