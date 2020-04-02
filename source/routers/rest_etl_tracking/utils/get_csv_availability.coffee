fs = require 'fs'
moment = require 'moment'

config = require '../../../../_config'
context_name = config.current_context

dateUtils = require './_date_utils'
theoreticalDatesOfYearMonth = dateUtils.theoreticalDatesOfYearMonth
isValidDate = dateUtils.isValidDate

# ======
# CSV's
# ======
csv_dir =
    nodejs: config.contexts[context_name].csv_dir_nodejs
    tweepy: config.contexts[context_name].csv_dir_tweepy

# Busca la disponibilidad de CSV's en un year_month para un extractor
# --------------------------------------------------------------------
getAavailableCSVsByYearMonth = (year_month, extractor) ->
    if extractor not in ['nodejs', 'tweepy']
        return {error: "Invalid extractor name: #{extractor}"}

    if not isValidDate("#{year_month}-01")
        return {error: "Invalid year_month: #{year_month}"}
    else
        year = /^(\d\d\d\d)-\d\d/.exec(year_month)[1]

    path = "#{csv_dir[extractor]}/#{year}"
    try
        ficheros = fs.readdirSync path
        csv_dates = ficheros.map (csv) -> /^(\d\d\d\d-\d\d-\d\d)/.exec(csv)[1]

        theoretical_dates = theoreticalDatesOfYearMonth year_month

        if theoretical_dates.constructor is Array  # significa que no hay error
            available_dates = []
            theoretical_dates.forEach (date) ->
                if date in csv_dates then value = 'ok' else value = 'missing'
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

    catch
        return {error: "CSV path not exist: #{path}"}


module.exports =
    getAavailableCSVsByYearMonth: getAavailableCSVsByYearMonth


# =====
# TEST
# =====
# console.log JSON.stringify getAavailableCSVsByYearMonth('2015-06', 'tweepy'), null, 2
# console.log JSON.stringify getAavailableCSVsByYearMonth('2016-06', 'nodejs'), null, 2
# console.log JSON.stringify getAavailableCSVsByYearMonth('2017-01', 'nodejs'), null, 2
# console.log JSON.stringify getAavailableCSVsByYearMonth('2017-01', 'tweepy'), null, 2
