CREATE OR REPLACE FUNCTION public.conciliacionbancaria_movsigessinconciliardesdehastaxls(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;
    datoconciliacion RECORD;
    rconc record;

BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
SELECT INTO rconc * 
	FROM cuentabancariasosunc 
	WHERE idcuentabancaria = rfiltros.idcuentabancaria;
  
  CREATE TEMP TABLE temp_conciliacionbancaria_movsigessinconciliardesdehastaxls
   AS (
SELECT fechacompr,elcomprobante,detalle,monto,round((impconc::numeric),2) as impconc,
'1-Fecha#fechacompr@2-Comprobante#elcomprobante@3-Detalle#detalle@4-Monto#monto@5-SinConciliar#impconc'::text as mapeocampocolumna

 from
(
  SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(
	concat(
		'{idcentroconciliacionbancaria=',null,
		', idconciliacionbancaria=',null,
		',  todos=false, 
			movfechadesde=',rfiltros.fechadesde, 
		' , tipoComp=OPC, 
			cadena=null, 
			nrocuentac=',rconc.nrocuentac,
		', movfechahasta=',rfiltros.fechahasta,'}') )

WHERE FALSE or  impconc >0

union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(
	concat('{idcentroconciliacionbancaria=',null,
		', idconciliacionbancaria=',null,
		',  todos=false, movfechadesde=', rfiltros.fechadesde,
		' , tipoComp=FA, cadena=null, nrocuentac=',rconc.nrocuentac,
		', movfechahasta=',rfiltros.fechahasta,'}') )

WHERE FALSE or  impconc >0

union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(
	concat('{idcentroconciliacionbancaria=',null,
		', idconciliacionbancaria=',null,
		',  todos=false, movfechadesde=', rfiltros.fechadesde , 
		' , tipoComp=MIN, cadena=null,  nrocuentac=',rconc.nrocuentac,
		', movfechahasta=',rfiltros.fechahasta,'}') )

WHERE FALSE or  impconc >0

union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(
	concat(
		'{idcentroconciliacionbancaria=',null,
		', idconciliacionbancaria=',null,
		',  todos=false, movfechadesde=', rfiltros.fechadesde, 
		' , tipoComp=RE|Descuento UNC|not ilike, cadena=null,  nrocuentac=',rconc.nrocuentac,
		', movfechahasta=',rfiltros.fechahasta,'}') )

WHERE FALSE or  impconc >0

union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(
	concat(
		'{idcentroconciliacionbancaria=',null,
		', idconciliacionbancaria=',null,
		',todos=false, movfechadesde=', rfiltros.fechadesde, 
		' , tipoComp=LT, cadena=null,  nrocuentac=',rconc.nrocuentac,
		', movfechahasta=',rfiltros.fechahasta,'}') )

WHERE FALSE or  impconc >0

order by fechacompr
) 
as g);
   

return true;
END;
$function$
