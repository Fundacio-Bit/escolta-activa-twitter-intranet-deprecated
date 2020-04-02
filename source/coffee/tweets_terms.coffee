# =========================================
# Autor: Esteve Lladó (Fundació Bit), 2016
# =========================================

# -------------------
# Variables Globales
# -------------------
g_dictionary = []

# -------------------------------------------------------------
# Función filtra entradas de diccionario por marca y categoría
# -------------------------------------------------------------
filterEntries = (dictionary, brand, category) ->
    if brand isnt '--all--' and category isnt '--all--'
        filteredDictionary = dictionary.filter (x) -> x.brand is brand and x.category is category
    else if brand is '--all--' and category is '--all--'
        filteredDictionary = dictionary
    else
        filteredDictionary = dictionary.filter (x) -> x.brand is brand or x.category is category

    # Ordenamos resultados por nombre canónico
    # -----------------------------------------
    compare = (a,b) ->
        if (a._canonical_name < b._canonical_name)
            return -1
        if (a._canonical_name > b._canonical_name)
            return 1
        return 0

    filteredDictionary.sort compare

    filteredDictionary


# ---------------------------------
# Función que carga el diccionario
# ---------------------------------
loadDictionaryTerms = ->
    request = "/rest_dictionary_terms/entries/category/--all--/brand/--all--"
    $.ajax({url: request, type: "GET"})
    .done (data) ->
        if data.error?
            alert "Error carregant diccionari: #{data.error}"
        else
            g_dictionary = data.results
            g_dictionary.forEach (x) -> x._canonical_name = "[#{x.brand}][#{x.category}] #{x._canonical_name}"

(($) ->

    # Función para extraer las marcas de la REST y renderizar resultados
    # ------------------------------------------------------------------
    getBrands = () ->
        brand_list = []
        request = "/rest_utils/brands"
        $.ajax({url: request, type: "GET"})
        .done (data) ->

            # Chequeamos si la REST ha devuelto un error
            # -------------------------------------------
            if data.error?
                $('#statusPanel').html MyApp.templates.commonsRestApiError {message: data.error}
            else
                data.results.forEach (brand) ->
                    brand_list.push({'value': brand, 'name': brand.charAt(0).toUpperCase() + brand.slice(1)})
                html_content = MyApp.templates.selectBrands {entries: brand_list, mandatory: true }
                $('#form-group-brands').html html_content
                html_content = MyApp.templates.selectBrands {entries: brand_list, all: true }
                $('#form-group-brands-category').html html_content


    # Cargamos diccionario
    # ---------------------
    loadDictionaryTerms()


    # Inicializamos datepickers
    # --------------------------
    $('#searchFormAlias input[name="yearmonth"]').datepicker
        format: "yyyy-mm"
        startView: 1
        minViewMode: 1
        language: "ca"

    $('#searchFormDictEntry input[name="yearmonth"]').datepicker
        format: "yyyy-mm"
        startView: 1
        minViewMode: 1
        language: "ca"


    # Función para extraer datos de la REST y renderizar resultados
    # --------------------------------------------------------------
    getDataAndRenderTable = (yearmonth, marca, termino) ->
        request = "/rest_tweets_retweets/retweets/yearmonth/#{yearmonth}/brand/#{marca}/terms/#{termino.trim()}"
        $.ajax({url: request, type: "GET"})
        .done (data) ->

            # Chequeamos si la REST ha devuelto un error
            # -------------------------------------------
            if data.error?
                $('#statusPanel').html MyApp.templates.commonsRestApiError {message: data.error}
            else
                # Renderizamos tabla de retweets
                # -------------------------------
                tweets = []
                data.results.forEach (doc) ->
                    new_retweets = doc.retweets
                    new_retweets.forEach (x) -> x.date = doc.date
                    tweets = tweets.concat new_retweets

                # Si hay más de 10000 retweets quitamos progresivamente para agilizar renderizado
                # --------------------------------------------------------------------------------
                cut_count = 1
                filterTweets = ->
                    if tweets.length > 10000
                        tweets = tweets.filter (x) -> x.count > cut_count
                        cut_count++
                        filterTweets()

                filterTweets()

                # Marcamos la fecha del primer retweet de cada día para diferenciar entre días
                # -----------------------------------------------------------------------------
                current_date = ''
                tweets.forEach (x) ->
                    if x.date isnt current_date
                        current_date = x.date
                        x.date = "<span class=\"label label-warning\">#{x.date.toUpperCase()}</span>"

                tweets = tweets.map (tweet) ->
                    search_date: tweet.date
                    count: tweet.count
                    brand: tweet.brand.toUpperCase()
                    date: tweet.ori_date
                    text: tweet.text.replace /(https?:\/\/[^ ]+)/g, '<a target="_blank" href="$1">$1</a>'
                    user_name: tweet.ori_user_name
                    user_location: tweet.ori_user_location

                setTimeout ( ->
                    html_content = MyApp.templates.retweetsTable {total_tweets: tweets.length, tweets: tweets}
                    $('#retweetsTable').html html_content
                    $('#statusPanel').html ''
                ), 600

                $('#statusPanel').html '<br><br><br><p align="center"><img src="/img/rendering.gif">&nbsp;&nbsp;Renderitzant taula de tweets.&nbsp;<strong>Per favor, esperi...</strong></p>'


    # Fijamos evento sobre botón de buscar retweets por Alias
    # --------------------------------------------------------
    $('#searchButtonAlias').click (event) ->
        event.preventDefault()  # evitamos el comportamiento por defecto del submit

        yearmonth = $('#searchFormAlias input[name="yearmonth"]').val()
        marca = $('#searchFormAlias select[name="brand"]').val()
        termino = $('#searchFormAlias input[name="term"]').val()
        termino = termino.replace /#/g, '<hashtag>'

        # =========================
        # Validación de formulario
        # =========================
        if yearmonth is ''
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'mes'}
        else if marca is null
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'marca'}
        else if termino is ''
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'terme'}
        else
            # ==============
            # Validación OK
            # ==============

            # controlamos visibilidad de elementos
            # -------------------------------------
            $('#retweetsTable').html ''
            $('#statusPanel').html '<br><br><br><p align="center"><img src="/img/loading_icon.gif">&nbsp;&nbsp;Carregant...</p>'

            getDataAndRenderTable yearmonth, marca, termino

        return false


    # Fijamos evento sobre botón de Borrar formulario en form de Alias
    # -----------------------------------------------------------------
    $('#resetButtonAlias').click (event) ->
        $('#statusPanel').html ''
        $('#retweetsTable').html ''


    # Función que actualiza una lista desplegable de nombres canónicos
    # -----------------------------------------------------------------
    refreshCanonicalSelectList = (filteredDictionary, formName) ->
        $("#{formName} select[name=\"canonicalName\"]").html ''
        $.each filteredDictionary, (i, item) ->
            $("#{formName} select[name=\"canonicalName\"]").append $('<option>', {value: item._id, text : item._canonical_name })

        $("#{formName} select[name=\"canonicalName\"] option:eq(0)").prop('selected', true)  # seleccionamos la primera opción


    # Fijamos evento sobre selects de 'Marca'
    # ----------------------------------------
    # $('#searchFormDictEntry select[name=\"brand\"]').change ->
    $('#form-group-brands-category').change ->
        marca = $('#searchFormDictEntry select[name="brand"]').val()
        categoria = $('#searchFormDictEntry select[name="category"]').val()
        filteredDictionary = filterEntries g_dictionary, marca, categoria
        refreshCanonicalSelectList filteredDictionary, '#searchFormDictEntry'


    # Fijamos evento sobre selects de 'Categoría'
    # --------------------------------------------
    $('#searchFormDictEntry select[name=\"category\"]').change ->
        marca = $('#searchFormDictEntry select[name="brand"]').val()
        categoria = $('#searchFormDictEntry select[name="category"]').val()
        filteredDictionary = filterEntries g_dictionary, marca, categoria
        refreshCanonicalSelectList filteredDictionary, '#searchFormDictEntry'


    # Fijamos evento sobre botón de buscar
    # -------------------------------------
    $('#searchButtonDictEntry').click (event) ->
        event.preventDefault()

        yearmonth = $('#searchFormDictEntry input[name="yearmonth"]').val()
        canonicalId = $('#searchFormDictEntry select[name="canonicalName"]').val()

        if yearmonth is ''
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'mes'}
        else if canonicalId is '-1'
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'marca i/o categoria'}
        else
            # ==============
            # Validación OK
            # ==============

            # Cogemos los valores del canónico seleccionado
            # ----------------------------------------------
            items = g_dictionary.filter (x) -> x._id is canonicalId
            item = items[0]
            marca = item.brand
            termino = item.alias.replace /#/g, '<hashtag>'

            # controlamos visibilidad de elementos
            # -------------------------------------
            $('#retweetsTable').html ''
            $('#statusPanel').html '<br><br><br><p align="center"><img src="/img/loading_icon.gif">&nbsp;&nbsp;Carregant...</p>'

            getDataAndRenderTable yearmonth, marca, termino

        return false


    # Ocultaciones al inicio
    # -----------------------
    getBrands()
    $('#statusPanel').html ''
    $('#retweetsTable').html ''

) jQuery