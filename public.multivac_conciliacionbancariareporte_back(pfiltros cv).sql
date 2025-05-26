CREATE OR REPLACE FUNCTION public.multivac_conciliacionbancariareporte_back(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

	rfiltros RECORD;
	
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   --RAISE NOTICE 'another_func(%)',rfiltros.idturismoadmin;

--   bmfecha bmcodigo bmconcepto bmdebito bmcredito bmsaldo elcomprobantesiges elmontosiges cbiimporte

CREATE TEMP TABLE temp_multivac_conciliacionbancariareporte
AS (
	SELECT split_part(elcomprobantesiges, '$', 1 )  as compsiges
         ,split_part(elcomprobantesiges, '$', 2 )::DOUBLE PRECISION as montosiges
         ,bmfecha
         ,bmcodigo
         ,bmconcepto
         ,bmdebito
         ,bmcredito
         ,bmsaldo
         ,cbiimporte
 ,'1-CompSiges#compsiges@2-MontoSiges#montosiges@3-Fecha Movimiento#bmfecha@4-Codigoc#bmcodigo@5-Concpeto#bmconcepto@6-Debito#bmdebito@7-Credito#bmcredito@8-Saldo#bmsaldo@9-ImpConciliado#cbiimporte'::text as mapeocampocolumna



   FROM (
        SELECT CASE WHEN not nullvalue(idconciliacionbancariaitem) THEN
                      conciliacionbancaria_formatcomprobante(              concat('idconciliacionbancariaitem=',idconciliacionbancariaitem,',idcentroconciliacionbancariaitem=',idcentroconciliacionbancariaitem ))
                ELSE 'S/C $ 0'
                END as elcomprobantesiges, *
        FROM bancamovimiento
        NATURAL JOIN bancamovimientocodigo
        LEFT JOIN conciliacionbancariaitem USING (idbancamovimiento)
        LEFT JOIN conciliacionbancaria USING (idconciliacionbancaria,idcentroconciliacionbancaria)
        LEFT JOIN conciliacionbancariaestado   USING (idconciliacionbancaria,idcentroconciliacionbancaria)
        LEFT JOIN conciliacionbancariaestadotipo USING ( idconciliacionbancariaestadotipo)

        WHERE  bmfecha >=rfiltros.bmfechadesde
               and bmfecha<=rfiltros.bmfechahasta
               and ((not nullvalue (conciliacionbancariaitem.idbancamovimiento)and cbiactivo ) or nullvalue (conciliacionbancariaitem.idbancamovimiento) )
   ) as t
   ORDER BY bmfecha
   );


return true;
END;
$function$
