# ==================================================================================
# Autor: Esteve Lladó (Fundació Bit), 2016.
# Uso:
#       'gulp' ejecuta todas las tareas.
#
#       'gulp watch' vigila cambios en:
#           - Scripts de CoffeeScript a transpilar,
#           - Templates Handlebars a compilar,
# ==================================================================================

gulp = require 'gulp'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
declare = require 'gulp-declare'
handlebars = require 'gulp-handlebars'
wrap = require 'gulp-wrap'
uglify = require 'gulp-uglify'
sourcemaps = require 'gulp-sourcemaps'


# ------------------------------------------------
# Reubicación de Librerías JavaScript en 'public'
# ------------------------------------------------
arrayBuildJS = [
    'node_modules/jquery/dist/*.min.js'
    'node_modules/bootstrap/dist/js/*.min.js'
    'node_modules/bootstrap-fileinput/js/*.min.js'
    'node_modules/bootstrap-fileinput/js/locales/ca.js'
    'node_modules/gulp-handlebars/node_modules/handlebars/dist/*.min.js'  # Importante: usaremos el handlebars runtime de gulp, que está asociado al handlebars compiler de gulp usado más abajo.
    'node_modules/bootstrap-datepicker/dist/js/*.min.js'
    'node_modules/bootstrap-datepicker/dist/locales/*.min.js'
    'node_modules/bootstrap-year-calendar/js/*.min.js'
    'node_modules/bootstrap-year-calendar/js/languages/*.js'
    'node_modules/chart.js/dist/*.js'
    'node_modules/charts-color/*.js'
    'node_modules/charts-color-string/*.js'
]
gulp.task 'build-js', ->
    gulp.src(arrayBuildJS)
    .pipe gulp.dest 'public/lib/js'


# -----------------------------------------
# Reubicación de Librerías CSS en 'public'
# -----------------------------------------
arrayBuildCSS = [
    'node_modules/bootstrap/dist/css/*.min.css'
    'node_modules/bootstrap-fileinput/css/*.min.css'
    'node_modules/bootstrap-datepicker/dist/css/*.min.css'
    'node_modules/bootstrap-year-calendar/css/*.min.css'
]
gulp.task 'build-css', ->
    gulp.src(arrayBuildCSS)
    .pipe gulp.dest 'public/lib/css'


# -----------------------------------
# Reubicación de Fuentes en 'public'
# -----------------------------------
gulp.task 'build-fonts', ->
    gulp.src('node_modules/bootstrap/dist/fonts/*.*')
    .pipe gulp.dest 'public/lib/fonts'


# ------------------------------------
# Reubicación de Imágenes en 'public'
# ------------------------------------
gulp.task 'build-images', ->
    gulp.src('source/img/*.*')
    .pipe gulp.dest 'public/img'


# ------------------------------------
# Reubicación de Mapas en 'public'
# ------------------------------------
gulp.task 'build-static', ->
    gulp.src('source/static/*.*')
    .pipe gulp.dest 'public/static'


# --------------------------------------------------------------------------------------
# Reubicación de Imágenes en 'public' (caso especial de 'loading.gif' para 'fileinput')
# --------------------------------------------------------------------------------------
gulp.task 'build-images-fileinput', ->
    gulp.src('source/img/loading.gif')
    .pipe gulp.dest 'public/lib/img'


arrayBuildTasks = [
    'build-js'
    'build-css'
    'build-fonts'
    'build-images'
    'build-images-fileinput'
    'build-static'
]
gulp.task 'build-lib', arrayBuildTasks, ->
    console.log "\nReubicadas librerías JavaScript, ficheros CSS, ficheros de fuentes, imágenes y mapas.\n"


# -----------------------------------------------
# Compilación de templates Handlebars (y uglify)
# -----------------------------------------------
arrayTemplatesSources = [
    'source/templates/*.hbs'
    'views/partials/menubar.handlebars'
]
gulp.task 'templates', ->
    gulp.src(arrayTemplatesSources)
    .pipe(handlebars())
    .pipe(wrap('Handlebars.template(<%= contents %>)'))
    .pipe(declare({
        namespace: 'MyApp.templates',
        noRedeclare: true,  # Avoid duplicate declarations
    }))
    .pipe(concat('templates.js'))
    .pipe(uglify())
    .pipe(gulp.dest('public/js'))

gulp.task 'build-templates', ['templates'], ->
    console.log "\nCompilados templates Handlebars.\n"


# ------------------------------------------------------------------------------
# Compilación de ficheros CoffeeScript del servidor server.coffee y la REST API
# ------------------------------------------------------------------------------

# every coffe has been transpiled using the gulp-sourcemaps module.
# this is necessary for the debugger to map from the coffee files to the corresponding
# js code. The jasvascript files cannot be uglified because that would prevent a correct 
# mapping.
gulp.task 'compile-server', ->
    gulp.src('server.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest(''))

gulp.task 'compile-config', ->
    gulp.src('_config.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest(''))

gulp.task 'compile-router_1', ->
    gulp.src('source/routers/rest_tweets_retweets/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_tweets_retweets/'))

gulp.task 'compile-router_2', ->
    gulp.src('source/routers/rest_etl_tracking/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_etl_tracking/'))

    gulp.src('source/routers/rest_etl_tracking/utils/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_etl_tracking/utils/'))

gulp.task 'compile-router_3', ->
    gulp.src('source/routers/rest_dictionary_terms/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_dictionary_terms/'))

    gulp.src('source/routers/rest_dictionary_terms/utils/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_dictionary_terms/utils/'))

gulp.task 'compile-router_4', ->
    gulp.src('source/routers/rest_reporting/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_reporting/'))

gulp.task 'compile-router_5', ->
    gulp.src('source/routers/rest_dictionary_influencers/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_dictionary_influencers/'))

gulp.task 'compile-router_6', ->
    gulp.src('source/routers/rest_utils/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_utils/'))

gulp.task 'compile-router_7', ->
    gulp.src('source/routers/rest_maps/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_maps/'))

gulp.task 'compile-router_8', ->
    gulp.src('source/routers/rest_blacklists/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_blacklists/'))

gulp.task 'compile-router_9', ->
    gulp.src('source/routers/rest_reporting_covid/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_reporting_covid/'))

gulp.task 'compile-router_10', ->
    gulp.src('source/routers/rest_reporting_airlines/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('source/routers/rest_reporting_airlines/'))

gulp.task 'compile-server-rest-coffee', ['compile-server', 'compile-config', 'compile-router_1', 'compile-router_2', 'compile-router_3', 'compile-router_4', 'compile-router_5', 'compile-router_6', 'compile-router_7', 'compile-router_8', 'compile-router_9', 'compile-router_10'], ->
    console.log "\nCompilados scripts de CoffeeScript de 'server.coffee' y routers REST.\n"


# ------------------------------------------------
# Compilación de ficheros CoffeeScript (y uglify)
# ------------------------------------------------
gulp.task 'compile-coffee', ->
    gulp.src('source/coffee/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee())
        # .pipe(uglify())
        .pipe(sourcemaps.write())
        .pipe(gulp.dest('public/js'))

gulp.task 'compile-coffee-frontend', ['compile-coffee'], ->
    console.log "\nCompilados scripts de CoffeeScript del FrontEnd.\n"


# ==============
# DEFAULT TASKS
# ==============
arrayDefaultTasks = [
    'build-lib'
    'build-templates'
    'compile-server-rest-coffee'
    'compile-coffee-frontend'
]
gulp.task 'default', arrayDefaultTasks, ->
    console.log "\nFIN!\n"


# =========
# WATCHERS (Nota: Faltan watchers para server.coffee, _config.coffee y routers REST)
# =========

# Vigila cambios en templates Handlebars para compilar
# -----------------------------------------------------
gulp.task 'watch-handlebars-templates', ->
    gulp.watch arrayTemplatesSources, ['build-templates']

# Vigila cambios en ficheros CoffeeScript para transpilar
# --------------------------------------------------------
gulp.task 'watch-coffee-scripts', ->
    gulp.watch 'source/coffee/*.coffee', ['compile-coffee-frontend']

# Ponemos todos los vigilantes en marcha
# ---------------------------------------
arrayWatchers = [
    'watch-coffee-scripts'
    'watch-handlebars-templates'
]
gulp.task 'watch', arrayWatchers
