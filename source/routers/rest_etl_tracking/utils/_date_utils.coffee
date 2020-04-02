moment = require 'moment'

# -------------------------------
# Comprueba validez de una fecha
# -------------------------------
isValidDate = (date) ->
    if date.match /^\d\d\d\d-\d\d-\d\d$/
        if moment(date, 'YYYY-MM-DD').format('YYYY-MM-DD') isnt 'Invalid date'
            return true
        else
            return false
    else
        return false


# --------------------------------------------------------------------------------------
# Saca los días de un mes-año concreto. El formato del parámetro debe ser 'YYYY-MM-DD'.
# Si se trata del mes presente, entonces saca los días pasados hasta 'ayer' (incluido).
# --------------------------------------------------------------------------------------
theoreticalDatesOfYearMonth = (year_month) ->
    if not isValidDate("#{year_month}-01")
        return {error: "Invalid year_month: #{year_month}"}

    today_yearmonth = moment().format 'YYYYMM'  # sin guión para pasar a integer

    if year_month.replace('-', '') is today_yearmonth
        mydate = "#{year_month}-01"
        today = moment().format 'YYYY-MM-DD'
        theoretical_dates = []
        while mydate isnt today
            theoretical_dates.push mydate
            mydate = moment(mydate, 'YYYY-MM-DD').add(1, 'days').format 'YYYY-MM-DD'
        return theoretical_dates

    else if parseInt(year_month.replace('-', '') ,10) > parseInt(today_yearmonth, 10)
        return {error: "Invalid year_month: #{year_month}, it is a future date"}

    else if parseInt(year_month.replace('-', '') ,10) < parseInt(today_yearmonth, 10)
        mydate = "#{year_month}-01"
        last_date = moment(mydate, 'YYYY-MM-DD').add(1, 'month').format 'YYYY-MM-DD'
        theoretical_dates = []
        while mydate isnt last_date
            theoretical_dates.push mydate
            mydate = moment(mydate, 'YYYY-MM-DD').add(1, 'days').format 'YYYY-MM-DD'
        return theoretical_dates


module.exports =
    isValidDate: isValidDate
    theoreticalDatesOfYearMonth: theoreticalDatesOfYearMonth


# =====
# TEST
# =====
# console.log theoreticalDatesOfYearMonth '2016-06'
