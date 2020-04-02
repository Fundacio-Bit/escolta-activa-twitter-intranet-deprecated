moment = require 'moment'

dateUtils = require './_date_utils'
theoreticalDatesOfYearMonth = dateUtils.theoreticalDatesOfYearMonth


# Busca la disponibilidad de documentos de un year_month para una colección Mongo.
# col_dates: es el array de items resultado de la consulta a Mongo para el year_month.
# -------------------------------------------------------------------------------------
getAavailableMongoDocsByYearMonth = (col_dates) ->

    # sacamos el year_month del contexto actual (col_dates)
    # ------------------------------------------------------
    year_month = /^(\d\d\d\d-\d\d)-\d\d/.exec(col_dates[0])[1]

    theoretical_dates = theoreticalDatesOfYearMonth year_month
    if theoretical_dates.constructor is Array  # significa que no hay error
        available_dates = []
        theoretical_dates.forEach (date) ->
            if date in col_dates then value = 'ok' else value = 'missing'
            avail_item = { day: moment(date, 'YYYY-MM-DD').format 'D' }
            avail_item[value] = true
            available_dates.push avail_item

        # En el caso de que year_month sea el mes en curso,
        # falta rellenar los días futuros hasta que acaba el mes.
        # --------------------------------------------------------
        if year_month is moment().format('YYYY-MM')
            mydate = "#{year_month}-01"
            last_date = moment(mydate, 'YYYY-MM-DD').add(1, 'month').format 'YYYY-MM-DD'
            current_month_dates = []
            while mydate isnt last_date
                current_month_dates.push mydate
                mydate = moment(mydate, 'YYYY-MM-DD').add(1, 'days').format 'YYYY-MM-DD'

            current_month_dates.forEach (date) ->
                day = moment(date, 'YYYY-MM-DD').format 'D'
                if day not in (x.day for x in available_dates)
                    avail_item = { day: day }
                    avail_item['padding'] = true
                    available_dates.push avail_item

        return available_dates

    else
        return theoretical_dates  # se trata de un error


module.exports =
    getAavailableMongoDocsByYearMonth: getAavailableMongoDocsByYearMonth


# =====
# TEST
# =====
# console.log getAavailableMongoDocsByYearMonth(['2017-01-01'])
