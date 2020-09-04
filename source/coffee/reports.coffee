# =========================================
# Author: Esteve Lladó (Fundació Bit), 2017
# Modified by: Elena Aguado and Óscar Moya
# =========================================

refreshIntervalId = 0

g_dictionary_categories = ['esdeveniments', 'esports', 'toponims', 'platges', 'patrimoni', 'naturalesa']

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

g_zip_status = {}  # it will save the zip status for each yearmonth

(($) ->

    # ---------------------------------------------------------
    # Function to fix EVENTS over the reports items in the list
    # ---------------------------------------------------------
    setEventsOnReportsList = (source) ->

        # -----------------------------------------------------
        # EVENT: Alert buttons in case of ZIP generation error
        # -----------------------------------------------------
        $('a.error_message').unbind().click (event) ->
            event.preventDefault()
            yearmonth = $(this).attr('month')

            alert g_zip_status[yearmonth].error_message

            return false

        # -------------------------------------
        # EVENT: Buttons to generate ZIP files
        # -------------------------------------
        $('button[month]').unbind().click (event) ->
            event.preventDefault()
            yearmonth = $(this).attr('month')

            # Call REST API to generate the ZIP file
            # -------------------------------------------------------------
            request = "/rest_reporting/reports/#{source}/generate/zip/yearmonth/#{yearmonth}"
            $.ajax({url: request, type: "GET"})
            .done (data) ->
                if data.error?
                    console.log("ERROR: #{JSON.stringify data.error}")
                    alert "ERROR: #{JSON.stringify data.error}"
                    return false
                else
                    return false
            $("#zip_status_#{yearmonth}").html '<span style="color: #00CC00; font-weight: bold;">Generant ZIP...</span>&nbsp;&nbsp;&nbsp;<img src="/img/loading_icon.gif">'
            return false


    # ------------------------------------------
    # Function that refreshes the reports list
    # -------------------------------------------
    refreshReportsList = (year, source) ->
        request = "/rest_reporting/reports/#{source}/year/#{year}"

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
                reports = data.results

                reports.forEach (report) ->

                    report.source = source  # fix the source

                    # Save the zip state globally
                    # ---------------------------
                    g_zip_status[report.month] = report.zip_status
                    
                    # Save the twet count time series globally
                    # ----------------------------------------
                    g_tweet_counts[report.month] = report.tweet_counts

                    # Save the language globally
                    # -----------------------------------------
                    g_language_counts[report.month] = report.language_counts

                    # Status of the ZIP file (errors, presence/absence and generation button)
                    # NOTE: this HTML content will appear only when the status is 'READY_TO_GENERATE'
                    # ------------------------------------------------------------------------------
                    zip_html = ''

                    zip_html += "<div id=\"zip_status_#{report.month}\">"

                    # Error messge alert
                    # ------------------
                    if report.zip_status.error_message isnt ''
                        zip_html += "<a href=\"#\" class=\"error_message\" month=\"#{report.month}\"><img src=\"/img/warning_icon.png\" width=\"50\" height=\"50\"></a>&nbsp;&nbsp;"

                    # ZIP download (if it exists)
                    # ---------------------------
                    if report.zip_exists
                        rest_url_to_zip = "/rest_reporting/reports/#{source}/zip/yearmonth/#{report.month}"  # llamada REST que devuelve el ZIP
                        zip_html += "<a href=\"#{rest_url_to_zip}\"><img src=\"/img/file-zip-icon.png\" width=\"60\" height=\"60\"></a>&nbsp;&nbsp;"

                    # ZIP generation button
                    # ---------------------
                    zip_html += "<button type=\"button\" class=\"btn btn-default\" month=\"#{report.month}\">Genera ZIP</button></div>"

                    zip_html += "</div>"

                    report.zip_html = zip_html

                # Render the reports list
                # -----------------------
                html_content = MyApp.templates.reportsTable
                    total_reports: reports.length
                    reports: reports
                    source: source.toUpperCase()

                $('#reportsTable').html html_content
                $('#statusPanel').html ''

                # Activate all eventos once the reports list has been rendered
                # -------------------------------------------------------------
                setEventsOnReportsList source


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
            $('#reportsTable').html ''
            $('#statusPanel').html '<br><br><br><p align="center"><img src="/img/rendering.gif">&nbsp;&nbsp;Carregant reports...</p>'

            # Render the reports list by the first time 
            # -----------------------------------------
            setTimeout ( -> refreshReportsList g_current_year, g_current_source ), 1000

            # ----------------------------------------------
            # Refresh the reports limits at every time interval
            # -----------------------------------------------
            if refreshIntervalId
                clearInterval(refreshIntervalId);
            refreshIntervalId = setInterval ( ->
                refreshReportsList g_current_year, g_current_source
                ), 7000
            # -----------------------------------------------------------

        return false

    # Initial elements hidding
    # ------------------------
    $('#statusPanel').html ''
    $('#reportsTable').html ''

) jQuery
