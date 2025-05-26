CREATE OR REPLACE FUNCTION public.tesoreria_reintegrospracticas_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        
	rfiltros record;
        
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_tesoreria_reintegrospracticas_contemporal
AS (
	
SELECT concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' , to_char(nrofactura, '00000000')) AS nrofacturaconformato,fechaemision, importeefectivo as importeOT, CONCAT(idcentroregional, '-', nroreintegro, '-', anio) as elreintegro, concat(nroorden, '-',centro) as laorden, 
nrocuentac, desccuenta, 

concat(cctipofactura , ' ' ,  ccpuntodeventa , '-' , to_char(ccnrocomprobante, '00000000'))
 /*concat(cctipofactura , ' ' , to_char(ccpuntodeventa::integer, '0000') , ccpuntodeventa'-' , to_char(ccnrocomprobante, '00000000')) AS */comprobantereintegro

,afil.nrodoc as afilnrodoc, afil.barra as afilbarra,
titu.nrodoc as titunrodoc, titu.barra as titubarra
-- fechaemision	nrofacturaconformato	importeot	desccuenta	comprobantereintegro	laorden	nrocuentac	elreintegro

,'1-fechaemision#fechaemision@2-nrofacturaconformato#nrofacturaconformato@3-importeot#importeot@4-desccuenta#desccuenta@5-comprobantereintegro#comprobantereintegro@6-laorden#laorden@7-nrocuentac#nrocuentac@8-elreintegro#elreintegro@9-afilnrodoc#afilnrodoc@10-afilbarra#afilbarra@11-titunrodoc#titunrodoc@12-titubarra#titubarra'::text as mapeocampocolumna
 
FROM facturaventa NATURAL JOIN informefacturacion NATURAL JOIN informefacturacionexpendioreintegro NATURAL JOIN reintegroorden  
 LEFT JOIN catalogoordencomprobante USING(nroorden,centro)  LEFT JOIN catalogocomprobante USING (idcatalogocomprobante, idcentrocatalogocomprobante)
NATURAL JOIN itemvalorizada NATURAL JOIN item NATURAL JOIN practica NATURAL JOIN cuentascontables

left  join consumo using(nroorden,centro)
left join persona afil on(consumo.nrodoc = afil.nrodoc)
left join persona titu on(facturaventa.nrodoc = titu.nrodoc)

WHERE fechaemision >=rfiltros.fechadesde AND fechaemision <=rfiltros.fechahasta
ORDER BY nrofactura
	

);
  

return true;
END;
$function$
