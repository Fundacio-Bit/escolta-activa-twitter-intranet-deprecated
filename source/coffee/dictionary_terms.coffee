# =========================================
# Autor: Esteve Lladó (Fundació Bit), 2016
# =========================================

(($) ->

    g_entries = []  # var global con la lista de entradas que servirá para refrescar después de borrar una entrada


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
                html_content = MyApp.templates.selectBrands {entries: brand_list, all_brands: true, label: true }
                $('#form-group-brands').html html_content
                html_content = MyApp.templates.selectBrandsModal {entries: brand_list, all_brands: true, label: true }
                $('#form-group-brands-modal').html html_content

    # Extraer las marcas de la REST y renderizar resultados
    # -----------------------------------------------------
    getBrands()


    # =======================================================================================
    # EVENTOS SOBRE COLUMNAS DE LA TABLA DE ENTRADAS
    # =======================================================================================

    setEventsOnEntriesTable = ->

        # --------------------------------------
        # Fijamos evento sobre columna de alias
        # --------------------------------------
        $('td.updateAlias').click ->
            myid = $(this).attr('id')
            myCanonicalName = $(this).attr('name')
            mytext = $(this).text()
            alias = (al.trim() for al in mytext.split(','))

            $('#updateAliasList').html '<br><br><br><p align="center"><img src="/img/rendering.gif">&nbsp;&nbsp;Carregant...</p>'
            $('#updateAliasModal').modal 'show'  # mostramos el modal

            setTimeout ( ->

                # Eliminamos posibles duplicados
                # -------------------------------
                uniqueAlias = []
                alias.forEach (x) -> if x not in uniqueAlias then uniqueAlias.push x

                # Descartamos alias que tienen caracteres extraños a una sublista en rojo
                # ------------------------------------------------------------------------
                discardedAlias = []
                purgedAlias = []
                uniqueAlias.forEach (al) ->
                    if al[0] is '#'  # hashtag
                        if /^#[a-z0-9_]+$/.test(al) then purgedAlias.push(al) else discardedAlias.push(al)
                    else
                        if /^[a-z0-9\s&]+$/.test(al) then purgedAlias.push(al) else discardedAlias.push(al)

                # Sacamos otros alias candidatos a partir del nombre canónico con la REST
                # ------------------------------------------------------------------------
                request = "/rest_dictionary_terms/alias/canonical_name/#{myCanonicalName}"

                $.ajax({url: request, type: "GET"})
                .done (data) ->
                    # Chequeamos si la REST ha devuelto un error
                    # -------------------------------------------
                    if data.error?
                        $('#updateAliasList').html ''
                        alert "ERROR: #{JSON.stringify data.error}"
                    else
                        # =================
                        # Petición REST OK
                        # =================
                        restAlias = data.results

                        # Eliminamos posibles duplicados
                        # -------------------------------
                        otherCandidateAlias = []
                        restAlias.forEach (x) -> if x not in otherCandidateAlias then otherCandidateAlias.push x

                        # Formateamos para pintar el template
                        # ------------------------------------
                        discardedAlias = discardedAlias.map (alias) -> {alias: alias}
                        purgedAlias = purgedAlias.map (alias) -> {alias: alias}
                        otherCandidateAlias = otherCandidateAlias.map (alias) -> {alias: alias}

                        html_content = MyApp.templates.listDictionaryCandidateAlias {candidate_alias: purgedAlias, discarded_alias: discardedAlias, other_alias: otherCandidateAlias}
                        $('#updateAliasList').html html_content

                        # ---------------------------------------------------------------
                        # Modal: Fijamos evento sobre botón de 'Añadir alias a la lista'
                        # ---------------------------------------------------------------
                        $('#updateAliasModal #addNewAliasButton').click (event) ->
                            event.preventDefault()

                            new_alias = $('#updateAliasModal #addNewAliasForm input[name="newAlias"]').val()
                            new_alias = new_alias.trim()
                            if new_alias isnt '' and not /^\s+$/.test(new_alias)

                                # Chequeamos el nuevo alias
                                # --------------------------
                                is_correct = false
                                if new_alias[0] is '#'  # si es hashtag
                                    if /^#[a-z0-9_]+$/.test(new_alias)
                                        is_correct = true
                                    else
                                        alert 'ERROR: HASHTAG INCORRECTE! Revisi que no contengui caràcters prohibits (espais, majúscules, accents, signes de puntuació). GUIA: Sols es permeten caràcters alfanumèrics [a-z] i [0-9] (sense ñ), i underscore (_).'
                                else
                                    if /^[a-z0-9\s&]+$/.test(new_alias)
                                        is_correct = true
                                        new_alias = new_alias.trim().replace /\s+/g, ' '
                                    else
                                        alert 'ERROR: ALIAS INCORRECTE! Revisi que no contengui caràcters prohibits (majúscules, accents, signes de puntuació). GUIA: Sols es permeten caràcters alfanumèrics [a-z] i [0-9] (sense ñ), espais entre paraules, i umpersand (&).'

                                if is_correct

                                    # Comprobamos si hay alias repetidos en la lista antes de seleccionar
                                    # --------------------------------------------------------------------
                                    current_alias = []
                                    $('#updateAliasModal #checkboxAliasListForm input[name="aliasCheckBox"]').each (e) ->
                                        current_alias.push $(this).val()

                                    if new_alias not in current_alias
                                        $('#updateAliasModal #saveButton').before "<div class=\"checkbox\"><label><input type=\"checkbox\" class=\"check\" name=\"aliasCheckBox\" value=\"#{new_alias}\">&nbsp;<i>#{new_alias}</i></label></div>"
                                    else
                                        alert "ERROR: L'àlies '#{new_alias}' està repetit a la llista."

                            return false

                        # -----------------------------------------------
                        # Modal: Fijamos evento sobre botón de 'Guardar'
                        # -----------------------------------------------
                        $('#updateAliasModal #saveButton').click (event) ->
                            event.preventDefault()

                            # Recogemos los alias seleccionados
                            # ----------------------------------
                            alias = []
                            $('#updateAliasModal #checkboxAliasListForm input[name="aliasCheckBox"]:checked').each (e) ->
                                alias.push $(this).val()

                            # Eliminamos posibles duplicados de la selección
                            # -----------------------------------------------
                            uniqueAlias = []
                            alias.forEach (x) -> if x not in uniqueAlias then uniqueAlias.push x

                            if uniqueAlias.length is 0
                                alert "ERROR: No ha escollit cap àlies de la llista!"
                            else

                                # Comprobamos que no hay alias solapados entre ellos
                                # ---------------------------------------------------
                                hay_solapados = false
                                ngrams = uniqueAlias.filter (x) -> x[0] isnt '#'
                                for x in ngrams
                                    for y in ngrams
                                        if x isnt y
                                            if x in y.split /\s+/
                                                alert "ERROR: L'àlies '#{x}' està contingut dins '#{y}'. Descarti algun dels dos."
                                                hay_solapados = true
                                                break

                                if not hay_solapados
                                    updateConfirmed = confirm "Validació de regles OK!\n\n" + "Nous àlies = #{uniqueAlias.join(', ')}\n\nVol MODIFICAR l'entrada?"
                                    if updateConfirmed
                                        # ==============
                                        # Validación OK
                                        # ==============
                                        request = "/rest_dictionary_terms/entries/id/#{myid}"
                                        $.ajax({
                                            url: request,
                                            type: "PUT",
                                            contentType: "application/json",
                                            accepts: "application/json",
                                            cache: false,
                                            dataType: 'json',
                                            data: JSON.stringify({updatedAlias: uniqueAlias}),
                                            error: (jqXHR) -> console.log "Ajax error: " + jqXHR.status
                                        }).done (data) ->
                                            # -------------------------------------------
                                            # Procesamos el resultado de la petición PUT
                                            # -------------------------------------------
                                            if data.error?
                                                alert "ERROR: #{JSON.stringify data.error}"
                                            else
                                                # alert "#{data.results}"

                                                # Cerramos modal
                                                # ---------------
                                                $('#updateAliasModal').modal 'hide'

                                                # Actualizamos columna
                                                # ---------------------
                                                $("td.updateAlias[id=\"#{myid}\"]").css "background-color", "#ddffdd"
                                                $("td.updateAlias[id=\"#{myid}\"]").html "<i>#{uniqueAlias.join ', '}</i>"

                            return false

            ), 600  # cierra el timeout


        # ---------------------------------------
        # Fijamos evento sobre columna de status
        # ---------------------------------------
        $('td.updateStatus').click ->
            myid = $(this).attr('id')
            mystatus = $(this).text()

            # cambiamos el estado como un interruptor on/off (PENDENT o vacío)
            # -----------------------------------------------------------------
            change_status = false
            if mystatus is 'PENDENT'
                changeConfirmed = confirm "Vol llevar l'estat 'PENDENT' d'aquesta entrada?"
                if changeConfirmed
                    change_status = true
                    newstatus = 'none'  # cualquier cosa distinta de 'PENDENT' sirve para borrar el estado
            else
                changeConfirmed = confirm "Vol posar l'estat a 'PENDENT' per aquesta entrada?"
                if changeConfirmed
                    change_status = true
                    newstatus = 'PENDENT'

            if change_status
                request = "/rest_dictionary_terms/entries/id/#{myid}/status/#{newstatus}"
                $.ajax({url: request, type: "GET"})
                .done (data) ->

                    # Chequeamos si la REST ha devuelto un error
                    # -------------------------------------------
                    if data.error?
                        alert data.error
                    else
                        # =================
                        # Petición REST OK
                        # =================

                        # Modificamos el valor de la columna de la tabla
                        # -----------------------------------------------
                        if newstatus is 'none' then newstatus = ''
                        $("td.updateStatus[id=\"#{myid}\"]").html "<span class=\"label label-danger\">#{newstatus}</span>"

            return false

        # ------------------------------------------------
        # Fijamos evento sobre columna de borrar entradas
        # ------------------------------------------------
        $('td.remove a').click ->
            entryIdToDelete = $(this).attr('href')
            acceptClicked = confirm "Segur que vol esborrar l'entrada?"
            if acceptClicked then deleteDictionaryEntry entryIdToDelete
            return false



    # =====================================================================================
    # DELETE DE ENTRADAS
    # =====================================================================================

    # ------------------------------------------------
    # Función para borrar una entrada del diccionario
    # ------------------------------------------------
    deleteDictionaryEntry = (id) ->
        request = "/rest_dictionary_terms/entries/delete/id/#{id}"
        $.ajax({url: request, type: "GET"})
        .done (data) ->

            # Chequeamos si la REST ha devuelto un error
            # -------------------------------------------
            if data.error?
                alert data.error
            else
                # =================
                # Petición REST OK
                # =================

                # refrescamos la tabla de entradas
                # ---------------------------------
                $('#statusPanel').html ''

                g_entries = g_entries.filter (x) -> x._id isnt id

                if g_entries.length > 0
                    html_content = MyApp.templates.dictionaryTable {total_entries: g_entries.length, entries: g_entries}
                    $('#dictionaryTable').html html_content
                    setEventsOnEntriesTable()
                else
                    $('#dictionaryTable').html ''



    # =====================================================================================
    # BÚSQUEDA (SEARCH) DE ENTRADAS
    # =====================================================================================

    # ---------------------------------------------------------------------------------
    # Función para extraer entradas del diccionario de la REST y renderizar resultados
    # ---------------------------------------------------------------------------------
    getDictionaryEntriesAndRenderTable = (request) ->
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
                entries = data.results
                entries.forEach (x) ->
                    x.brand = x.brand.toUpperCase()
                    x.category = x.category.toUpperCase()
                    x.alias = (al.trim() for al in x.alias.split(',')).join ', '
                    if not x.status? then x.status = ''

                g_entries = entries  # servirá para refrescar después de borrar una entrada

                setTimeout ( ->
                    # -------------------
                    # Renderizamos tabla
                    # -------------------
                    html_content = MyApp.templates.dictionaryTable {total_entries: entries.length, entries: entries}
                    $('#dictionaryTable').html html_content
                    $('#statusPanel').html ''
                    setEventsOnEntriesTable()
                ), 600

                $('#statusPanel').html '<br><br><br><p align="center"><img src="/img/rendering.gif">&nbsp;&nbsp;Carregant...</p>'


    # -------------------------------------
    # Fijamos evento sobre botón de Buscar
    # -------------------------------------
    $('#searchButton').click ->
        categoria = $('#searchForm select[name="category"]').val()
        marca = $('#searchForm select[name="brand"]').val()

        # controlamos visibilidad de elementos
        # -------------------------------------
        $('#dictionaryTable').html ''
        $('#statusPanel').html ''

        # Petición REST
        # --------------
        request = "/rest_dictionary_terms/entries/category/#{categoria}/brand/#{marca}"
        getDictionaryEntriesAndRenderTable request

        return false



    # =====================================================================================
    # MODAL DE NUEVAS ENTRADAS
    # =====================================================================================

    # ----------------------------------------------
    # Fijamos evento sobre botón de 'Crear entrada'
    # ----------------------------------------------
    $('#createButton').click ->
        $('#resetBasicDataButton').click()  # clickamos 'netejar' para limpiar formulario
        $('#createNewEntryModal').modal 'show'  # mostramos el modal
        return false


    # -----------------------------------------------------------
    # Fijamos evento sobre el primer botón de borrar formularios
    # -----------------------------------------------------------
    $('#resetBasicDataButton').click ->
        $('#candidateAliasList').html ''
        $('#statusPanelModal').html ''


    # ----------------------------------------------------------------
    # Modal: Fijamos evento sobre botón de 'Generar alias candidatos'
    # ----------------------------------------------------------------
    $('#generateCandidateAliasButton').click (event) ->
        event.preventDefault()

        $('#statusPanelModal').html ''

        # Recogemos los campos del formulario
        # ------------------------------------
        brands = []
        $('#form-group-brands-modal input[name="brand"]:checked').each (e) ->
            brands.push $(this).val()

        newEntry =
            brands: brands
            category: $('#basicDataNewEntryForm select[name="category"]').val()
            _canonical_name: $('#basicDataNewEntryForm input[name="canonicalName"]').val()

        # Validamos los campos
        # ---------------------
        if newEntry.brands.length == 0
            setTimeout ( -> $('#brandError').html '' ), 1500
            $('#brandError').html MyApp.templates.commonsModalFormValidation {message: 'Falta triar una <b>marca</b>'}
        else if newEntry.category is null
            setTimeout ( -> $('#categoryError').html '' ), 1500
            $('#categoryError').html MyApp.templates.commonsModalFormValidation {message: 'Falta triar una <b>categoria</b>'}
        else if newEntry._canonical_name is ''
            setTimeout ( -> $('#canonicalNameError').html '' ), 1500
            $('#canonicalNameError').html MyApp.templates.commonsModalFormValidation {message: 'Falta omplir el <b>nom can&ograve;nic</b>'}
        else
            # ==============
            # Validación OK
            # ==============
            $('#candidateAliasList').html '<img src="/img/rendering.gif">'

            request = "/rest_dictionary_terms/alias/canonical_name/#{newEntry._canonical_name}"

            $.ajax({url: request, type: "GET"})
            .done (data) ->
                # Chequeamos si la REST ha devuelto un error
                # -------------------------------------------
                if data.error?
                    $('#candidateAliasList').html ''
                    $('#statusPanelModal').html MyApp.templates.commonsModalCreateNewEntry {state: 'danger', glyphicon: 'alert', message: "Error: #{JSON.stringify data.error}"}
                else
                    # =================
                    # Petición REST OK
                    # =================
                    candidate_alias = data.results
                    candidate_alias = candidate_alias.map (alias) -> {alias: alias}
                    html_content = MyApp.templates.listDictionaryCandidateAlias {candidate_alias: candidate_alias}
                    $('#candidateAliasList').html html_content

                    # ---------------------------------------------------------------
                    # Modal: Fijamos evento sobre botón de 'Añadir alias a la lista'
                    # ---------------------------------------------------------------
                    $('#createNewEntryModal #addNewAliasButton').click (event) ->
                        event.preventDefault()

                        new_alias = $('#createNewEntryModal #addNewAliasForm input[name="newAlias"]').val()
                        new_alias = new_alias.trim()
                        if new_alias isnt '' and not /^\s+$/.test(new_alias)

                            # Chequeamos el nuevo alias
                            # --------------------------
                            is_correct = false
                            if new_alias[0] is '#'  # si es hashtag
                                if /^#[a-z0-9_]+$/.test(new_alias)
                                    is_correct = true
                                else
                                    alert 'ERROR: HASHTAG INCORRECTE! Revisi que no contengui caràcters prohibits (espais, majúscules, accents, signes de puntuació). GUIA: Sols es permeten caràcters alfanumèrics [a-z] i [0-9] (sense ñ), i underscore (_).'
                            else
                                if /^[a-z0-9\s&]+$/.test(new_alias)
                                    is_correct = true
                                    new_alias = new_alias.trim().replace /\s+/g, ' '
                                else
                                    alert 'ERROR: ALIAS INCORRECTE! Revisi que no contengui caràcters prohibits (majúscules, accents, signes de puntuació). GUIA: Sols es permeten caràcters alfanumèrics [a-z] i [0-9] (sense ñ), espais entre paraules, i umpersand (&).'

                            if is_correct

                                # Comprobamos si hay alias repetidos en la lista antes de seleccionar
                                # --------------------------------------------------------------------
                                current_alias = []
                                $('#createNewEntryModal #checkboxAliasListForm input[name="aliasCheckBox"]').each (e) ->
                                    current_alias.push $(this).val()

                                if new_alias not in current_alias
                                    $('#createNewEntryModal #saveButton').before "<div class=\"checkbox\"><label><input type=\"checkbox\"  class=\"check\" name=\"aliasCheckBox\" value=\"#{new_alias}\">&nbsp;<i>#{new_alias}</i></label></div>"
                                else
                                    alert "ERROR: L'àlies '#{new_alias}' està repetit a la llista."

                        return false

                    # -------------------------------------------------------------
                    # Modal: Fijamos evento sobre botón de 'Guardar nueva entrada'
                    # -------------------------------------------------------------
                    $('#createNewEntryModal #saveButton').click (event) ->
                        event.preventDefault()

                        # # Recogemos los datos de la nueva entrada (para el nombre canónico se debe coger el que se usó para generar los alias)
                        # # ----------------------------------------
                        # newEntry.brand = $('#basicDataNewEntryForm select[name="brand"]').val()

                        # Recogemos los brands seleccionados
                        # ----------------------------------
                        brands = []
                        $('#form-group-brands-modal input[name="brand"]:checked').each (e) ->
                            brands.push $(this).val()
                        # newEntry.brands = brands

                        newEntry.category = $('#basicDataNewEntryForm select[name="category"]').val()

                        # Comprobamos que no haya comas y semicolons en el nombre canónico
                        # -----------------------------------------------------------------
                        if /(,|;)/.test newEntry._canonical_name
                            alert "ERROR: El nom canònic no pot contenir comes (,) o semicolons (;).\nEsborri'ls i tornar a clickar 'Generar àlies candidats' i a seleccionar els àlies."
                        else

                            # Recogemos los alias seleccionados
                            # ----------------------------------
                            alias = []
                            $('#createNewEntryModal #checkboxAliasListForm input[name="aliasCheckBox"]:checked').each (e) ->
                                alias.push $(this).val()

                            # Comprobamos que no hay alias solapados entre ellos
                            # ---------------------------------------------------
                            hay_solapados = false
                            ngrams = alias.filter (x) -> x[0] isnt '#'
                            for x in ngrams
                                for y in ngrams
                                    if x isnt y
                                        if x in y.split /\s+/
                                            alert "ERROR: L'àlies '#{x}' està contingut dins '#{y}'. Descarti algun dels dos."
                                            hay_solapados = true
                                            break

                            if not hay_solapados

                                # Eliminamos posibles duplicados
                                # -------------------------------
                                uniqueAlias = []
                                alias.forEach (x) -> if x not in uniqueAlias then uniqueAlias.push x

                                newEntry.alias = uniqueAlias
                                newEntryConfirmed = confirm "Validació de regles OK!\n\n" + "Marca = #{newEntry.brands}\nCategoria = #{newEntry.category}\nNom canònic = #{newEntry._canonical_name}\nAlias = #{newEntry.alias.join(', ')}\n\nVol GUARDAR la nova entrada?"
                                if newEntryConfirmed
                                    # ==============
                                    # Validación OK
                                    # ==============

                                    # Guardamos nuevas entradas en MongoDB
                                    # ------------------------------------
                                    for brand in brands
                                        newEntry.brand = brand
                                        $.ajax({
                                            url: '/rest_dictionary_terms/entries',
                                            type: "POST",
                                            contentType: "application/json",
                                            accepts: "application/json",
                                            cache: false,
                                            dataType: 'json',
                                            data: JSON.stringify(newEntry),
                                            error: (jqXHR) -> console.log "Ajax error: " + jqXHR.status
                                        }).done (result) ->
                                            # --------------------------------------------
                                            # Procesamos el resultado de la petición POST
                                            # --------------------------------------------
                                            if result.ok?
                                                $('#statusPanelModal').html MyApp.templates.commonsModalCreateNewEntry {state: 'success', glyphicon: 'ok', message: "Entrada creada correctament."}

                                                # Mostramos la entrada insertada
                                                # -------------------------------
                                                $('#resetSearchButton').click()  # limpiamos formulario de búsqueda del documento general
                                                $('#dictionaryTable').html ''
                                                $('#statusPanel').html ''
                                                request = "/rest_dictionary_terms/entries/id/#{result.id}"
                                                # getDictionaryEntriesAndRenderTable request

                                                setTimeout ( ->
                                                    $('#createNewEntryModal').modal 'hide'
                                                ), 1000

                                            else if result.error?
                                                $('#statusPanelModal').html MyApp.templates.commonsModalCreateNewEntry {state: 'danger', glyphicon: 'alert', message: "Error: #{result.error}"}
                                            else
                                                $('#statusPanelModal').html MyApp.templates.commonsModalCreateNewEntry {state: 'danger', glyphicon: 'alert', message: "No s'ha pogut guardar la nova entrada."}


    # # ------------------------------------------
    # # Fijamos evento al hacer chek en Select All
    # # ------------------------------------------
    # $('#checkAll').click (event) ->
    #     event.preventDefault()
    #     $('.check').prop 'checked', $(this).prop('checked')

    # Ocultaciones al inicio
    # -----------------------
    $('#statusPanel').html ''
    $('#dictionaryTable').html ''

) jQuery