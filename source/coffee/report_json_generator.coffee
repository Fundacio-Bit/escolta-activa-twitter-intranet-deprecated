# =========================================
# Autor: Esteve Lladó (Fundació Bit), 2017
# =========================================

(($) ->

    # # Inicializamos datepickers
    # # --------------------------
    # $('#searchForm input[name="yearmonth"]').datepicker
    #     format: "yyyy-mm"
    #     startView: 1
    #     minViewMode: 1
    #     language: "ca"


    # Función genera el JSON Report via REST (invoca Python Shell en el servidor)
    # ----------------------------------------------------------------------------
    generateJsonReportViaRest = (request) ->
        $.ajax({url: request, type: "GET"})
        .done (data) ->

            # Chequeamos si la REST ha devuelto un error
            # -------------------------------------------
            if data.error?
                $('#statusPanel').html MyApp.templates.commonsRestApiError {message: data.error}
            else
                # =================
                # Petición REST OK
                # =================
                if /<OK!>/.test data.results
                    $('#statusPanel').html '<div class="alert alert-success" role="alert">JSON report creat!</div>'
                else
                    $('#statusPanel').html '<div class="alert alert-danger" role="alert">S\'ha produ&iuml;t un error, per favor, contacti amb l\'administrador.</div>'


    # Fijamos evento sobre botón de generar JSON
    # -------------------------------------------
    $('#searchButton').click (event) ->
        event.preventDefault()  # evitamos el comportamiento por defecto del submit

        $('#statusPanel').html '<br>&nbsp;&nbsp;&nbsp;&nbsp;<img src="/img/loading_icon.gif">&nbsp;Generant JSON report...'

        # Petición REST
        # --------------
        request = "/rest_reporting/reports/twitter/generate/json"
        generateJsonReportViaRest request

        return false


    # Ocultaciones al inicio
    # -----------------------
    $('#statusPanel').html ''

) jQuery