CREATE OR REPLACE FUNCTION public.multivac_conciliacionbancariareporte(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   SELECT INTO rconciliacion *
   FROM conciliacionbancaria
   JOIN cuentabancariasosunc using (idcuentabancaria)
   WHERE idconciliacionbancaria = rfiltros.idconciliacionbancaria
         and idcentroconciliacionbancaria = rfiltros.idcentroconciliacionbancaria;
   perform  conciliacionbancaria_conciliarcuentacontable(concat('{fechaDesde=',rconciliacion.cbfechadesdemovimiento,',fechaHasta=',rconciliacion.cbfechahastamovimiento,', idcuenta=',rconciliacion.nrocuentac,', nrocuentac=',rconciliacion.nrocuentac,'}'));
   /* SELECT *
   FROM temp_asientogenerico_mayordecuenta_contemporal
   WHERE not nullvalue(idconciliacionbancariaitem)*/
   
   CREATE TEMP TABLE temp_multivac_conciliacionbancariareporte
   AS (
       SELECT idcuenta,idasiento, fechacontable::date,elidcomprobante,concepto ,d_h,	montoasiento,cbifechaingreso::date,	idconciliacionbancariaitem,montoconciliado
       ,'1-idcuenta#idcuenta@2-idasiento#idasiento@3-fechacontable#fechacontable@4-idcomprobante#elidcomprobante@5-leyenda#concepto@6-d_h#d_h@7-montoasiento#montoasiento@8-Fecha Conc.#cbifechaingreso@9-idItemCon#idconciliacionbancariaitem@9-MontoConc#montoconciliado'::text as mapeocampocolumna

       FROM temp_asientogenerico_mayordecuenta_contemporal_aux
       );
return true;
END;
$function$
