CREATE OR REPLACE FUNCTION public.tesoreria_facturacionorigentxt_contemporal(character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de alerta para la modificacion de precios de articulos de farmacia*/

DECLARE
	
	rfiltros RECORD;
	rusuario RECORD;
	resultado TEXT;
        vmes varchar;
        vanio varchar;

BEGIN
EXECUTE sys_dar_filtros($1) INTO rfiltros;
vanio  = EXTRACT(YEAR FROM rfiltros.fechadesde); 
vmes = lpad(EXTRACT(MONTH FROM rfiltros.fechadesde),2,'0') ;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
 
CREATE TEMP TABLE temp_tesoreria_facturacionorigentxt_contemporal
AS (

SELECT
fechamovimiento,
CASE WHEN idcomprobantetipos = 21 THEN 'Factura'
WHEN idcomprobantetipos IN (2,4,56,20,24) THEN 'ORDEN'
WHEN idcomprobantetipos = 7 THEN 'Turismo'
WHEN idcomprobantetipos = 17 THEN 'Plan de Pago'
ELSE 'OTRO' END as OrigenDeuda,
concat(informefacturacion.tipofactura,' ',informefacturacion.nrosucursal,' ',informefacturacion.nrofactura) as comprobante,
concat(nrodoc,'-',persona.barra::text) as nroafiliado,
concat(nombres,' ',apellido) as afiliado,
nrocuentac,idconcepto,importe,movconcepto
--,*
FROM public.enviodescontarctactev2
JOIN persona USING(nrodoc)
LEFT JOIN informefacturacion ON idcomprobantetipos = 21 AND idcomprobante = nroinforme*100+idcentroinformefacturacion
where idenviodescontarctacte = concat(vanio,vmes));

resultado =  '';
return resultado;
END;$function$
