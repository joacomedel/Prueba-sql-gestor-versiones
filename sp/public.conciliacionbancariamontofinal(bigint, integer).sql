CREATE OR REPLACE FUNCTION public.conciliacionbancariamontofinal(bigint, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE
    rliq RECORD;
    rusuario RECORD;
    cconciliacion CURSOR FOR SELECT * FROM temp_conciliacionbancaria;
    rconciliacion record;
    elidconciliacionbancaria bigint;
    elidcentroconciliacionbancaria integer;
   
    valor double precision;
BEGIN
valor=0;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;


SELECT  into valor cbsaldoinicialcb-(sum(CASE WHEN (bmdebito <> 0 ) THEN cbiimporte ELSE bmdebito END  ) )+
(
sum(CASE WHEN (bmcredito <> 0 ) THEN cbiimporte ELSE bmcredito END ) )  


FROM conciliacionbancaria
NATURAL JOIN conciliacionbancariaitem
JOIN bancamovimiento USING (idbancamovimiento)
 
WHERE   conciliacionbancaria.idconciliacionbancaria =$1
             and  conciliacionbancaria.idcentroconciliacionbancaria =$2
            AND cbiactivo
group by cbsaldoinicialcb;


return valor;
END;


$function$
