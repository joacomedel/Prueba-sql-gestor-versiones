CREATE OR REPLACE FUNCTION public.movsigessinconciliarxls(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

	rfiltros RECORD;
	rconciliacion RECORD;
        datoconciliacion RECORD;
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
    select into datoconciliacion * from conciliacionbancaria  JOIN cuentabancariasosunc using (idcuentabancaria)
     where idconciliacionbancaria=rfiltros.idconciliacionbancaria and  idcentroconciliacionbancaria=rfiltros.idcentroconciliacionbancaria ;

  
  CREATE TEMP TABLE temp_movsigessinconciliarxls
   AS (
    select fechacompr,elcomprobante,detalle,monto,round((impconc::numeric),2) as impconc, concat(idasientogenerico,'|',idcentroasientogenerico) as elasiento, agfechacontable,
    '1-Fecha#fechacompr@2-Comprobante#elcomprobante@3-Detalle#detalle@4-Monto#monto@5-SinConciliar#impconc@6-Asiento#elasiento@7-Fecha_Contable_Registro#agfechacontable'::text as mapeocampocolumna

 from
(
  SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',datoconciliacion.idcentroconciliacionbancaria,', idconciliacionbancaria=',datoconciliacion.idconciliacionbancaria,',  todos=false, movfechadesde=',datoconciliacion.cbfechadesdemovimiento, ' , tipoComp=OPC, cadena=null, nrocuentac=',datoconciliacion.nrocuentac,', movfechahasta=',datoconciliacion.cbfechahastamovimiento,'}') )
WHERE FALSE or  impconc >0

union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',datoconciliacion.idcentroconciliacionbancaria,', idconciliacionbancaria=',datoconciliacion.idconciliacionbancaria,',  todos=false, movfechadesde=', datoconciliacion.cbfechadesdemovimiento , ' , tipoComp=FA, cadena=null, nrocuentac=',datoconciliacion.nrocuentac,', movfechahasta=',datoconciliacion.cbfechahastamovimiento,'}') )
WHERE FALSE or  impconc >0

union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',datoconciliacion.idcentroconciliacionbancaria,', idconciliacionbancaria=',datoconciliacion.idconciliacionbancaria,',  todos=false, movfechadesde=', datoconciliacion.cbfechadesdemovimiento , ' , tipoComp=MIN, cadena=null,  nrocuentac=',datoconciliacion.nrocuentac,', movfechahasta=',datoconciliacion.cbfechahastamovimiento,'}') )
WHERE FALSE or  impconc >0

union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',datoconciliacion.idcentroconciliacionbancaria,', idconciliacionbancaria=',datoconciliacion.idconciliacionbancaria,',  todos=false, movfechadesde=', datoconciliacion.cbfechadesdemovimiento, ' , tipoComp=RE|Descuento UNC|not ilike, cadena=null,  nrocuentac=',datoconciliacion.nrocuentac,', movfechahasta=',datoconciliacion.cbfechahastamovimiento,'}') )
WHERE FALSE or  impconc >0

union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',datoconciliacion.idcentroconciliacionbancaria,', idconciliacionbancaria=',datoconciliacion.idconciliacionbancaria,',todos=false, movfechadesde=', datoconciliacion.cbfechadesdemovimiento, ' , tipoComp=LT, cadena=null,  nrocuentac=',datoconciliacion.nrocuentac,', movfechahasta=',datoconciliacion.cbfechahastamovimiento,'}') )
WHERE FALSE or  impconc >0

--BelenA agrego que busque en el ultimo que agregue, el facomp
union
SELECT * , (1) as multiplicador
FROM conciliacionbancaria_darmovimientossinconciliar(concat('{idcentroconciliacionbancaria=',datoconciliacion.idcentroconciliacionbancaria,', idconciliacionbancaria=',datoconciliacion.idconciliacionbancaria,',todos=false, movfechadesde=', datoconciliacion.cbfechadesdemovimiento, ' , tipoComp=LT, cadena=null,  nrocuentac=',datoconciliacion.nrocuentac,', movfechahasta=',datoconciliacion.cbfechahastamovimiento,'}') )
WHERE FALSE or  impconc >0
order by fechacompr
) 
as g);
   

return true;
END;
$function$
