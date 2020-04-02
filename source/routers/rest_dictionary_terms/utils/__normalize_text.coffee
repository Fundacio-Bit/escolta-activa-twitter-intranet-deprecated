# =============================================================================================================
# Autor: Esteve Lladó, Fundació Bit (2016)
#
# Creado: 30 Octubre 2016
# =============================================================================================================

latinise = require './__latinise'
String.prototype.latinise = latinise.latinise

# -----------------------------------------------------------------------------------------------------
# Normaliza un texto (elimina diacríticos, caracteres especiales, retornos de carro y dobles espacios)
# -----------------------------------------------------------------------------------------------------
normalize_text = (texto) ->

    cadena = texto
    cadena = cadena.replace(/[\n\r]/g, ' ')  # quitamos retornos de carro
    cadena = cadena.trim().toLowerCase().latinise()

    cadena = cadena.replace(/-/g, ' ')
    cadena = cadena.replace(/–/g, ' ')  # guión raro (más largo)
    cadena = cadena.replace(/_/g, ' ')
    cadena = cadena.replace(/¬/g, ' ')  # otro guión raro
    cadena = cadena.replace(/&/g, 'and')

    cadena = cadena.replace(/[º<>`´·:'’"!¡,;#$%*@+\().//¨^~|=\[\]{}?¿]/g, '')

    cadena = cadena.split(/\s+/).join(' ')  # quita múltiples espacios entre palabras
    cadena = cadena.trim()

    return cadena

    # chequeamos que el resultado está bien normalizado
    # --------------------------------------------------
    # if cadena is ''
    #     return cadena
    # else if not /^[a-z0-9\s]+$/.test cadena
    #     return {error: "ERROR: El siguiente texto no se pudo normalizar porque contiene caracteres no permitidos: '#{cadena}'"}
    # else
    #     return cadena


module.exports = normalize_text
