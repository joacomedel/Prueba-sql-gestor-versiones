CREATE OR REPLACE FUNCTION public.darctacontablecomprobanteventa(pnroinforme bigint, pidcentroinformefacturacion integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
-- Parametro: Nroinforme, Idcentro
-- Return: nrocuentac
DECLARE
	vnrocuentac varchar;
BEGIN
	select into vnrocuentac mm.nrocuentac
	from informefacturacion if
	JOIN facturaventacupon fvc on (if.nrosucursal=fvc.nrosucursal and if.nrofactura=fvc.nrofactura and if.tipofactura=fvc.tipofactura and if.tipocomprobante=fvc.tipocomprobante)
	join valorescaja v using (idvalorescaja)
	join multivac.formapagotiposcuentafondos ff on(fvc.nrosucursal=ff.nrosucursal and fvc.idvalorescaja=ff.idvalorescaja)
	join multivac.mapeocuentasfondos mm using(idcuentafondos)	
	where if.nroinforme=pnroinforme and if.idcentroinformefacturacion=pidcentroinformefacturacion and v.idformapagotipos=3;	

	return vnrocuentac;
END;
$function$
