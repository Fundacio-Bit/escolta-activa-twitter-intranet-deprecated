# =========================================
# Author: Esteve Lladó (Fundació Bit), 2017
# Modified by: Elena Aguado and Óscar Moya
# =========================================

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

        # ----------------------------------------------------
        # EVENT: Button to open the modal 'Tweets escrutats' 
        # ----------------------------------------------------
        $('a.openTweetsEscrutats').unbind().click (event) ->
            event.preventDefault()
            yearmonth = $(this).attr('month')

            # Download CSV
            # -------------------------------------------
            $('#tweetsEscrutatsCSVPanel').html MyApp.templates.tweetsEscrutatsCSVLoad {yearmonth: yearmonth}
    
            # Generate array fo day numbers to write the series X Axis  
            # ---------------------------------------------------------
            year = yearmonth.split("-")[0]
            month = yearmonth.split("-")[1]
            last_day_in_month = new Date(year, month, 0).getDate()
            month_day_numbers = Array.from(Array(last_day_in_month + 1).keys()).slice(1)

            # Extract the series data per brand
            # ----------------------------------
            brand_colors =
                mallorca:
                    borderColor: "rgba(255,255,0, 0.8)"
                    backgroundColor: "rgba(255,255,0,0)"
                menorca:
                    borderColor: "rgba(0,128,0, 0.8)"
                    backgroundColor: "rgba(0,128,0,0)"
                ibiza:
                    borderColor: "rgba(255,0,0,0.8)"
                    backgroundColor: "rgba(255,0,0,0)"
                formentera:
                    borderColor: "rgba(0,0,255,0.8)"
                    backgroundColor: "rgba(0,0,255,0)"

            series = []
            g_brands.forEach (brand) ->
                series.push {
                        label: brand,
                        borderColor: brand_colors[brand].borderColor,
                        backgroundColor: brand_colors[brand].backgroundColor,
                        borderWidth: 2,
                        tension: 0,
                        radius: 0,
                        data: g_tweet_counts[yearmonth].series[brand]}

            
            ctx = document.getElementById('reportTweetCountsChart').getContext('2d')
            

            seriesChart = new Chart(ctx,{
                type: 'line'
                data:
                    labels: month_day_numbers
                    datasets : series
                options:
                    responsive: true
                    title:
                        display: true
                        text: "Sèries temporals de tweet counts"
                    tooltips: 
                        mode: 'x'
                        intersect: true
                        hover:
                            mode: 'nearest'
                            intersect: true
                    scales:
                        xAxes: [{
                            display: true
                            gridLines:
                                display: false
                            scaleLabel:
                                display: true
                                labelString: 'Data'
                            }]
                        yAxes: [{
                            display: true
                            gridLines:
                                display: false
                            scaleLabel:
                                display: true
                                labelString: 'Freqüència'
                            }]
                        })

            $('#reportTweetCountsChart').show()

            # Render the tweet counts table
            # -------------------------------
            tweet_counts_table = '<table width="100%" class="table table-striped table-condensed"><tr><td><b>marca</b></td><td><b>total</b></td><td><b>variació</b></td></tr>'

            g_brands.forEach (brand) ->
                tweet_counts_table += "<tr><td>#{brand}</td><td>#{g_tweet_counts[yearmonth].total[brand]}</td><td>#{g_tweet_counts[yearmonth].variation[brand]}</td></tr>"

            tweet_counts_table += '</table>'

            $("#reportTweetCountsTable").html tweet_counts_table

            # Fix title, current month and show modal 
            # ----------------------------------------
            $('#reportTweetsEscrutatsTitle').html "Edició de tweets escrutats de <strong>#{source.toUpperCase()}</strong> de <strong>#{yearmonth}</strong>"
            $('#reportTweetsEscrutatsStatusPanel').html ''
            $('#reportTweetsEscrutatsModal').modal 'show'  # show the modal

            # Include link to jump to the end of the page 
            # ---------------------------------------------
            $('.bottomLink').unbind().click ->
                $('#reportTweetsEscrutatsModal').animate
                    scrollTop: 10000

            return false

        # -----------------------------------------
        # EVENT: Button to open the modal 'Idiomes'
        # -----------------------------------------
        $('a.openIdiomes').unbind().click (event) ->
            event.preventDefault()
            yearmonth = $(this).attr('month')

            # Download CSV
            # -------------------------------------------
            $('#idiomesCSVPanel').html MyApp.templates.idiomesCSVLoad {yearmonth: yearmonth}

            # Draw the language counts table 
            # -------------------------------
            languages = ['es', 'ca', 'en', 'de', 'other', 'total']
            language_counts_table = '<table width="100%" class="table table-striped table-condensed">'

            language_counts_table += '<tr><td><b>idioma</b></td>'
            g_brands.forEach (brand) -> language_counts_table += "<td><b>#{brand}</b></td>"
            language_counts_table += '<td><b>Total</b></td><td><b>%Total</b></td>'
            language_counts_table += '</tr>'

            languages.forEach (lang) ->
                language_counts_table += "<tr><td>#{lang}</td>"
                g_brands.forEach (brand) ->
                    language_counts_table += "<td>#{g_language_counts[yearmonth][brand][lang]}</td>"
                language_counts_table += "<td>#{g_language_counts[yearmonth].per_lang[lang].count}</td>"
                language_counts_table += "<td>#{g_language_counts[yearmonth].per_lang[lang].percent}</td>"
                language_counts_table += "</tr>"

            language_counts_table += '</table>'
            $("#reportNotesLanguageCountsTable").html language_counts_table

            # Fix title, current month and show modal 
            # ---------------------------------------
            $('#reportIdiomesTitle').html "Edició de idiomes de <strong>#{source.toUpperCase()}</strong> de <strong>#{yearmonth}</strong>"
            $('#reportIdiomesStatusPanel').html ''
            $('#reportIdiomesModal').modal 'show'  # mostramos el modal

            # Include link to jump to the end of the page 
            # ---------------------------------------------
            $('.bottomLink').unbind().click ->
                $('#reportIdiomesModal').animate
                    scrollTop: 10000

            return false


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
            setInterval ( ->
                refreshReportsList g_current_year, g_current_source
                ), 7000
            # -----------------------------------------------------------

        return false

    # Initial elements hidding
    # ------------------------
    $('#statusPanel').html ''
    $('#reportsTable').html ''

) jQuery
