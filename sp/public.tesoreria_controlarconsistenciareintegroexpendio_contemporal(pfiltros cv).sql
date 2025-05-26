CREATE OR REPLACE FUNCTION public.tesoreria_controlarconsistenciareintegroexpendio_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_controlarconsistenciareintegroexpendio_contemporal
AS (
	SELECT DISTINCT *
	  --,'1-Edad#edad@2-Nombres#nombres@3-Apellido#apellido@4-Nrodoc#nrodoc@5-Nomenclador#idsubespecialidad@6-Capitulo#idcapitulo@7-SubCapitulo#idsubcapitulo@8-Practica#idpractica@4-Nombre#pdescripcion@4-Plan Cobertura#descripcion@4-Centro Regional#cregional@4-Asoc.#acdecripcion@4-Importe#importe@4-Cantidad#cantidad'::text as mapeocampocolumna 
	     FROM
		(
		select idordenpagocontable,idcentroordenpagocontable,nroordenpago,idcentroordenpago,nroorden,orden.centro,nrosucursal,nrofactura,tipocomprobante
		,tipofactura,idcomprobantetipos,facturaventa.fechaemision as fechaemisionot,reintegro.rimporte as importereintegro,infoorden.importeorden,ordenpago.importetotal as importeminuta

		--ordenpagocontableordenpago.*,facturaorden.*,reintegro.rimporte as importereintegro,infoorden.importeorden,ordenpago.importetotal as importeminuta
		from orden 
		natural join reintegroorden 
		natural join reintegro  
		NATURAL JOIN ordenpago
		NATURAL JOIN (SELECT nroorden,centro,sum(importe) as importeorden,fechaemision 
			       FROM orden 
				NATURAL JOIN consumo 
				NATURAL JOIN importesorden 
				WHERE not anulado and idformapagotipos <> 6 AND tipo = 55 
				GROUP BY nroorden,centro,fechaemision
				) as infoorden
		LEFT join facturaorden USING(nroorden,centro)
		LEFT JOIN facturaventa USING(nrosucursal,nrofactura,tipocomprobante,tipofactura)
		LEFT JOIN ordenpagocontableordenpago  USING(nroordenpago,idcentroordenpago)
		where abs(importeorden - rimporte) > 1 AND orden.fechaemision >=  '2018-06-01' --rfiltros.fechaemision
	) as t    
	

);
  

return true;
END;
$function$
