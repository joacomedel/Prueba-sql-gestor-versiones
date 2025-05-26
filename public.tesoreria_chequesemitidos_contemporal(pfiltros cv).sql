CREATE OR REPLACE FUNCTION public.tesoreria_chequesemitidos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
     
    CREATE TEMP TABLE temp_tesoreria_chequesemitidos_contemporal 
    AS (

        SELECT 
        CASE WHEN nullvalue(cetdescripcion) THEN 'Sin Estado'
                ELSE  cetdescripcion END as estadocheque,    
        --      popobservacion, 
                cheque.chnumero,
                cheque.cnumero,
                cheque.cmonto,
                cheque.cfechaconfeccion,
                cheque.cfechacobro,
            case  when idordenpagocontableestadotipo=6 then concat('OPC Anulada:',prestador.pdescripcion ,' OP: ' ,idordenpagocontable,'-',idcentroordenpagocontable )  else concat(prestador.pdescripcion ,' OP: ' ,idordenpagocontable,'-',idcentroordenpagocontable ) end as detalle,
            chequera.chnumerochequeini,
            chequera.chnumerochequefin,
            --chequeestadotipo.cetdescripcion as estadocheque,
            case when not nullvalue(idordenpagocontable)then concat(idordenpagocontable,'-',idcentroordenpagocontable )
            end as opc,
            opcobservacion,
            --opcetdescripcion,
            nrocuentabanco
            --,cuentabancariasosunc.nrocuentac
            ,'1-Cuenta Banco#nrocuentabanco@2-Chequera#chnumero@3-Inicio Chequera#chnumerochequeini@4-Fin Chequera#chnumerochequefin@5-Nº Cheque#cnumero@6-Fecha Confeccion#cfechaconfeccion@7-Fecha Cobro#cfechacobro@8-Monto#cmonto@9-OPC#opc@10-Observacion OPC#opcobservacion@11-Detalle#detalle@12-Estado Cheque#estadocheque'::text as mapeocampocolumna


        from    cheque      NATURAL JOIN chequera

        LEFT JOIN chequeestado using(idcheque,idcentrocheque)      NATURAL JOIN chequeratipo
        LEFT JOIN chequeestadotipo using(idchequeestadotipo)
        LEFT JOIN   pagoordenpagocontable       using(idcheque,idcentrocheque)
        LEFT JOIN   ordenpagocontable    using   (idordenpagocontable,idcentroordenpagocontable)
        LEFT JOIN   ordenpagocontableestado    using   (idordenpagocontable,idcentroordenpagocontable)
        LEFT JOIN   ordenpagocontableestadotipo    using   (idordenpagocontableestadotipo)
        LEFT JOIN prestador   using(idprestador)            JOIN cuentabancariasosunc using(idcuentabancaria)

         WHERE   true  

            AND ( CASE WHEN 0=rfiltros.idchequeestadotipo THEN nullvalue(idchequeestadotipo) ELSE
                CASE WHEN (6=rfiltros.idchequeestadotipo)=false THEN idchequeestadotipo=rfiltros.idchequeestadotipo ELSE
                true
                END
            END )

            AND chnumero=rfiltros.chnumero AND idcuentabancaria=rfiltros.idcuentabancaria
             and (nullvalue(cefechafin) or nullvalue(idcheque)) and nullvalue(opcfechafin)
             and cfechaconfeccion between rfiltros.fechainicio and rfiltros.fechafin
            ORDER BY  cheque.cnumero ASC
    );

    return true;
    END;



$function$
