CREATE OR REPLACE FUNCTION public.tesoreria_chequesemitidos_contemporal(pidctabancaria integer, pchnumero bigint, pfechaini date, pfechafin date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE
       
BEGIN
 
CREATE TEMP TABLE temp_tesoreria_chequesemitidos_contemporal 
AS (

SELECT case when nullvalue(cetdescripcion) then 'Sin Estado'
else  cetdescripcion end as estadocheque,	 
        popobservacion, cheque.*,
case  when idordenpagocontableestadotipo=6 then
concat('OPC Anulada:',prestador.pdescripcion ,' OP: ' ,idordenpagocontable,'-',idcentroordenpagocontable )  else
concat(prestador.pdescripcion ,' OP: ' ,idordenpagocontable,'-',idcentroordenpagocontable ) end as detalle,
chequera.chnumerochequeini,chequera.chnumerochequefin, 	chequeestadotipo.cetdescripcion,
case when not nullvalue(idordenpagocontable)then concat(idordenpagocontable,'-',idcentroordenpagocontable )
end as opc,opcobservacion,opcetdescripcion,nrocuentabanco,cuentabancariasosunc.nrocuentac

from 	cheque  	NATURAL JOIN chequera

left JOIN chequeestado using(idcheque,idcentrocheque)      NATURAL JOIN chequeratipo
  left JOIN chequeestadotipo using(idchequeestadotipo)
   left join   pagoordenpagocontable       using(idcheque,idcentrocheque)
  left join   ordenpagocontable    using   (idordenpagocontable,idcentroordenpagocontable)
left join   ordenpagocontableestado    using   (idordenpagocontable,idcentroordenpagocontable)
 left join   ordenpagocontableestadotipo    using   (idordenpagocontableestadotipo)
  left JOIN prestador	using(idprestador)            JOIN cuentabancariasosunc using(idcuentabancaria)

 WHERE   true  AND chnumero=pchnumero AND idcuentabancaria=pidctabancaria
 and (nullvalue(cefechafin) or nullvalue(idcheque)) and nullvalue(opcfechafin)
 and cfechaconfeccion between pfechaini and pfechafin
ORDER BY  cheque.cnumero ASC
);

return true;
END;

$function$
