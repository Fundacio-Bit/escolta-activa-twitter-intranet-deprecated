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


    # Función para extraer datos de la REST y renderizar resultados
    # --------------------------------------------------------------
    getSeriesDataAndRenderChart = (year, brand, terminos) ->
        request = "/rest_tweets_retweets/series/year/#{year}/brand/#{brand}/terms/#{terminos.trim()}"
        $.ajax({url: request, type: "GET"})
        .done (data) ->

            # Chequeamos si la REST ha devuelto un error
            # -------------------------------------------
            if data.error?
                $('#statusPanel').html MyApp.templates.commonsRestApiError {message: data.error}
                # Reset the canvas. If not several canvas could appear supperposed
                $('#seriesChart').remove()
                $('#chartContainer').append('<canvas id="seriesChart" width="70%" height="20px"></canvas>')
            else
                brandMessage = brand.charAt(0).toUpperCase() + brand.slice(1)
                # Reset the canvas. If not several canvas could appear supperposed
                $('#seriesChart').remove()
                $('#chartContainer').append('<canvas id="seriesChart" width="70%" height="20px"></canvas>')
                $('#statusPanel').html ''

                ctx = document.getElementById('seriesChart').getContext('2d');
                seriesChart = new Chart(ctx, {
                    type: 'line'
                    data: data.results
                    options:
                        responsive: true
                        title:
                            display: true
                            text: "Sèrie temporal de " + brandMessage + " a l'any " + year
                        legend:
                            display:false
                        tooltips:
                            mode: 'x'
                            intersect: true
                            hover:
                                mode: 'nearest'
                                intersect: true
                        scaleShowValues: true
                        scales:
                            xAxes: [ {
                                gridLines:
                                    display: false
                                # display: true
                                ticks:
                                    source: 'labels'
                                    autoSkip: false
                                scaleLabel:
                                    display: true
                                    labelString: 'Data'
                            } ]
                            yAxes: [ {
                                gridLines:
                                    display: false
                                # display: true
                                scaleLabel:
                                    display: true
                                    labelString: 'Freqüència'
                            } ]
                })

                $('#seriesChart').show()


    # Fijamos evento sobre botón de generar Serie Anual de Alias
    # -----------------------------------------------------------
    $('#searchButtonAlias').click (event) ->
        event.preventDefault()  # evitamos el comportamiento por defecto del submit

        # Reset the canvas. If not several canvas could appear supperposed
        $('#seriesChart').remove()
        $('#chartContainer').append('<canvas id="seriesChart" width="70%" height="20px"></canvas>')

        year = $('#searchFormAlias select[name="year"]').val()
        brand = $('#searchFormAlias select[name="brand"]').val()
        terminos = $('#searchFormAlias input[name="term"]').val()
        terminos = terminos.replace /#/g, '<hashtag>'

        # =========================
        # Validación de formulario
        # =========================
        if year is null
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'any'}
        else if brand is null
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'marca'}
        else if terminos is ''
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'termes'}
        else
            # ==============
            # Validación OK
            # ==============
            setTimeout ( ->
                getSeriesDataAndRenderChart year, brand, terminos
            ), 600
            # Reset the canvas. If not several canvas could appear supperposed
            $('#seriesChart').remove()
            $('#chartContainer').append('<canvas id="seriesChart" width="70%" height="20px"></canvas>')
            $('#statusPanel').html '<br><br><br><p align="center"><img src="/img/rendering.gif">&nbsp;&nbsp;Carregant...</p>'

        return false


    # Fijamos evento sobre botón de Borrar formulario (series anuales)
    # -----------------------------------------------------------------
    $('#resetButtonAlias').click (event) ->
        $('#statusPanel').html ''
        # Reset the canvas. If not several canvas could appear supperposed
        $('#seriesChart').remove()
        $('#chartContainer').append('<canvas id="seriesChart" width="70%" height="20px"></canvas>')


    # Función que actualiza una lista desplegable de nombres canónicos
    # -----------------------------------------------------------------
    refreshCanonicalSelectList = (filteredDictionary, formName) ->
        $("#{formName} select[name=\"canonicalName\"]").html ''
        $.each filteredDictionary, (i, item) ->
            $("#{formName} select[name=\"canonicalName\"]").append $('<option>', {value: item._id, text : item._canonical_name })

        $("#{formName} select[name=\"canonicalName\"] option:eq(0)").prop('selected', true)  # seleccionamos la primera opción


    # Fijamos evento sobre select de 'Brand' en Series Anuales de Canónicos
    # ----------------------------------------------------------------------
    $('#form-group-brands-category').change ->
        brand = $('#searchFormDictEntry select[name="brand"]').val()
        categoria = $('#searchFormDictEntry select[name="category"]').val()
        filteredDictionary = filterEntries g_dictionary, brand, categoria
        refreshCanonicalSelectList filteredDictionary, '#searchFormDictEntry'


    # Fijamos evento sobre select de 'Categoría' en Series Anuales de Canónicos
    # --------------------------------------------------------------------------
    $('#searchFormDictEntry select[name=\"category\"]').change ->
        brand = $('#searchFormDictEntry select[name="brand"]').val()
        categoria = $('#searchFormDictEntry select[name="category"]').val()
        filteredDictionary = filterEntries g_dictionary, brand, categoria
        refreshCanonicalSelectList filteredDictionary, '#searchFormDictEntry'


    # Fijamos evento sobre botón de generar Serie Anual de Nombre Canónico
    # ---------------------------------------------------------------------
    $('#searchButtonDictEntry').click (event) ->
        event.preventDefault()

        # Reset the canvas. If not several canvas could appear supperposed
        $('#seriesChart').remove()
        $('#chartContainer').append('<canvas id="seriesChart" width="70%" height="20px"></canvas>')

        year = $('#searchFormDictEntry select[name="year"]').val()
        canonicalId = $('#searchFormDictEntry select[name="canonicalName"]').val()
        # alert canonicalId

        if year is null
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'any'}
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
            brand = item.brand
            terminos = item.alias.replace /#/g, '<hashtag>'

            setTimeout ( ->
                getSeriesDataAndRenderChart year, brand, terminos
            ), 600
            $('#statusPanel').html '<br><br><br><p align="center"><img src="/img/rendering.gif">&nbsp;&nbsp;Carregant...</p>'
            # Reset the canvas. If not several canvas could appear supperposed
            $('#seriesChart').remove()
            $('#chartContainer').append('<canvas id="seriesChart" width="70%" height="20px"></canvas>')

        return false


    # Ocultaciones al inicio
    # -----------------------
    getBrands()
    $('#statusPanel').html ''
    # Reset the canvas. If not several canvas could appear supperposed
    $('#seriesChart').remove()
    $('#chartContainer').append('<canvas id="seriesChart" width="70%" height="20px"></canvas>')

) jQuery