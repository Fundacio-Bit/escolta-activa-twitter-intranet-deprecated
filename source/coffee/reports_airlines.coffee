# =========================================
# Author: Esteve Lladó (Fundació Bit), 2017
# Modified by: Elena Aguado and Óscar Moya
# =========================================

g_brands = []

# Function to extract the brands from the REST API and render the results
# ------------------------------------------------------------------------
getBrands = () ->
    brand_list = []
    request = "/rest_utils/brands"
    $.ajax({url: request, type: "GET"})
    .done (data) ->

        # Check if the REST API returned an error
        # ----------------------------------------
        if data.error?
            $('#statusPanel').html MyApp.templates.commonsRestApiError {message: data.error}
        else
            data.results.forEach (brand) ->
                brand_list.push(brand)
    return brand_list

g_brands = getBrands()

g_tweet_counts = {}  # it will save tweet count series globally for each yearmonth
g_language_counts = {}  # it will save language count globally for each yearmonth

(($) ->

    # ------------------------------------------
    # Function that refreshes the reports list
    # -------------------------------------------
    refreshReportsList = (year, source) ->
        request = "/rest_reporting_airlines/reports/#{source}/year/#{year}"

        $.ajax({url: request, type: "GET"})
        .done (data) ->

            # Check if the RSET API returned an error
            # ---------------------------------------
            if data.error?
                $('#statusPanel').html MyApp.templates.commonsRestApiError {message: data.error}
            else
                # =================
                # REST call OK
                # =================
                # console.log("RESULTS\n" + JSON.stringify(data.results))
                files = data.results
                reports = []
                index = 0
                files.forEach (file) ->
                    report = {}
                    report.source = source  # fix the source
                    report.date = file[0..9]

                    # CSV download
                    # ------------
                    csv_html = ''
                    if index%6 == 0
                        csv_html += "<tr>"
                    csv_html += "<td border=1 width='15%'>"
                    csv_html += "<div id=\"csv_#{report.date}\">"
                    rest_url_to_csv = "/rest_reporting_airlines/reports/#{source}/csv/date/#{report.date}"  # llamada REST que devuelve el ZIP
                    csv_html += "<a href=\"#{rest_url_to_csv}\"><img src=\"/img/csv_icon.png\" width=\"60\" height=\"60\"></a>"
                    csv_html += "<p><strong>#{report.date}</strong></p>"
                    csv_html += "</div>"
                    csv_html += "</td>"
                    if index%6 == 5
                        csv_html += "</tr>"

                    report.csv_html = csv_html
                    index +=1
                    reports.push(report)

                # Render the reports list
                # -----------------------
                html_content = MyApp.templates.reportsAirlinesTable
                    total_reports: reports.length
                    reports: reports
                    source: source.toUpperCase()


                $('#reportsAirlinesTable').html html_content
                $('#statusPanel').html ''


    # =================================
    # Fix event over the search button
    # ==================================
    $('#searchButton').unbind().click (event) ->
        event.preventDefault()  # avoid the submit default behaviour
 
        year = $('#searchForm select[name="year"]').val()
        source = 'twitter'

        # ================
        # Form validation
        # ================
        if year is null
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'any'}
        else if source is null
            setTimeout ( -> $('#statusPanel').html '' ), 1000
            $('#statusPanel').html MyApp.templates.commonsFormValidation {form_field: 'font'}
        else
            # ==============
            # Validation OK
            # ==============

            # fix values in global variables
            # ------------------------------
            g_current_year = year
            g_current_source = source

            # control elements visibility
            # ---------------------------
            $('#reportsAirlinesTable').html ''
            $('#statusPanel').html '<br><br><br><p align="center"><img src="/img/rendering.gif">&nbsp;&nbsp;Carregant reports...</p>'

            # Render the reports list by the first time 
            # -----------------------------------------
            setTimeout ( -> refreshReportsList g_current_year, g_current_source ), 1000

            # ----------------------------------------------
            # Refresh the reports limits at every time interval
            # -----------------------------------------------
            setInterval ( ->
                refreshReportsList g_current_year, g_current_source
                ), 7000
            # -----------------------------------------------------------

        return false

    # Initial elements hidding
    # ------------------------
    $('#statusPanel').html ''
    $('#reportsAirlinesTable').html ''

) jQuery
