# =========================================
# Autor: Esteve Lladó (Fundació Bit), 2016
# =========================================

# -----------------------------------------------------------
# Extrae disponibilidad de datos de la 'data admin' API REST
# -----------------------------------------------------------
getAvailableData = ->
    leadZero = (number) -> ('0' + number).slice(-2)  # helper para poner 0 delante del mes
    date = new Date()

    current_day = date.getDate()
    current_month = date.getMonth() + 1  # importante sumar 1
    current_year = date.getFullYear()
    if current_day is 1
        current_month -= 1
        if current_month is 0
            current_month = 12
            current_year -= 1

    year_month = "#{current_year}-#{leadZero(current_month)}"

    request = "/rest_data_admin/availability/year_month/#{year_month}"

    $.ajax({url: request, type: "GET"})
    .done (data) ->
        if data.error?
            $('#availabilityPanel').html '<br>' + MyApp.templates.commonsRestApiError {message: data.error}
        else
            html_content = MyApp.templates.availDataTable {availGroups: data.results, year_month: data.year_month.toUpperCase()}
            $('#availabilityPanel').html html_content


# ----------------------
# Ejecuciones al inicio
# ----------------------
(($) ->
    $('#availabilityPanel').html '<br><br><br><p align="center">Bienvenido a la intranet de ESCOLTA ACTIVA / TWITTER</p>'

) jQuery
