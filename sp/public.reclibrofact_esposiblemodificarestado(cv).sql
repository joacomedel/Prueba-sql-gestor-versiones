CREATE OR REPLACE FUNCTION public.reclibrofact_esposiblemodificarestado(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    rparam RECORD;
    respuesta boolean;
    srespuesta varchar;
    rexiste record;
    rtfvliquidacioniva record;
    rconcilbancaria RECORD;
BEGIN
    respuesta = false;
    EXECUTE sys_dar_filtros($1) INTO rparam;

    -----  BelenA:  me fijo si esta dentro de una conciliacion bancaria, si no lo está me deja modificar el comprobante, ticket 6092
    SELECT INTO rconcilbancaria *
    FROM rlf_precarga 
    LEFT JOIN reclibrofact USING    (idrlfprecarga,idcentrorlfprecarga)
    NATURAL JOIN conciliacionbancariaitem
    WHERE 
    rlf_precarga.idrlfprecarga=rparam.idrlfprecarga AND    rlf_precarga.idcentrorlfprecarga=rparam.idcentrorlfprecarga  AND
    cbiclavecompsiges ilike concat('idrecepcion=',reclibrofact.idrecepcion,'|idcentroregional=',reclibrofact.idcentroregional) AND cbiactivo;

    IF FOUND THEN
        srespuesta = concat('El comprobante se encuentra conciliado dentro de la Conciliacion Bancaria Nº ', rconcilbancaria.idconciliacionbancaria , 
            E'\n' ,'Si quiere modificar el estado del comprobante por favor desconciliarlo primero. ') ;
            
    END IF;


     
RETURN srespuesta;
END;
$function$
