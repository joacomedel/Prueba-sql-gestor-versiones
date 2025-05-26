CREATE OR REPLACE FUNCTION public.controles_facturacionfarmacia_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

-- GK 16-05-2022 - Agrego fecha facturación
-- GK 17-10-2022 - Cambios solicitados por usuario importe total / unitario y diferentes cobertueas
CREATE TEMP TABLE temp_controles_facturacionfarmacia_contemporal
AS (
	SELECT *,
	  --,'1-Edad#edad@2-Nombres#nombres@3-Apellido#apellido@4-Nrodoc#nrodoc@5-Nomenclador#idsubespecialidad@6-Capitulo#idcapitulo@7-SubCapitulo#idsubcapitulo@8-Practica#idpractica@4-Nombre#pdescripcion@4-Plan Cobertura#descripcion@4-Centro Regional#cregional@4-Asoc.#acdecripcion@4-Importe#importe@4-Cantidad#cantidad'::text as mapeocampocolumna 
	  '1-Factura#factura@2-Nro Orden#nroorden@3-Fecha Facturacion#fechaventa@4-Cliente#nombreapellido@5-Nro Doc#nrodoc@6-Descripcion#descripcion@7-Cod Barra#mcodbarra@8-Id articuloS#idarticulo@9-ivaio#iva@10-Cantidadc#cantidad@11-DescuentoS#descuento@12-Precio lista#preciolista@13-ImporteIva#importeiva@14- importedesc#importedesc@15- precioventa#precioventa@16- Total#total'::text as mapeocampocolumna 
	FROM (
			SELECT 
			concat(tipofactura, nrosucursal,'-',nrofactura,' ', tipocomprobante) as factura,
			concat(' OV ',idordenventa,'-',idcentroordenventa)  as nroorden,
			fechaemision as fechaventa,
			aapellidoynombre as nombreapellido,
			fa.nrodoc,
			acodigobarra as mcodbarra,
			descripcion,
		    ovi.idarticulo	as idarticulo
		   ,ovi.oviidiva as iva
		   ,ovi.ovicantidad as cantidad 
		   ,ovi.ovidescuento as descuento
		   ,ovi.ovipreciolista as preciolista
		   ,ovi.oviimporteiva as importeiva
		   ,ovi.oviimpdescuento	as importedesc
		   ,ovi.oviprecioventa 	as precioventa
			,
			CASE WHEN nullvalue(ovi.ovicantidad) 
     		THEN (
     			CASE WHEN tipofactura='NC' THEN
     				(-1*ifv.importe)
     			ELSE 
     				ifv.importe
     			END 
     			)
     		ELSE
     		(
			CASE WHEN tipofactura='NC' 
			THEN -1*(ovi.ovicantidad*ovi.oviprecioventa)   ELSE (ovi.ovicantidad*ovi.oviprecioventa)   END 
			)
			END as total	

		FROM facturaventa

		LEFT  JOIN itemfacturaventa ifv USING (tipofactura, tipocomprobante, nrosucursal, nrofactura)
		LEFT JOIN far_ordenventaitemitemfacturaventa USING (nrofactura,nrosucursal,tipocomprobante,tipofactura, iditem)
		LEFT JOIN far_ordenventaitem ovi USING ( 	idordenventaitem , 	idcentroordenventaitem)
		LEFT JOIN far_ordenventa USING (idordenventa,idcentroordenventa)
		LEFT JOIN far_articulo USING(idarticulo, idcentroarticulo)
		LEFT JOIN far_afiliado fa ON (fa.idafiliado =far_ordenventa.idafiliado	AND 	fa.idcentroafiliado =far_ordenventa.idcentroafiliado	)

		WHERE 

			(fechaemision >= rfiltros.fechadesde AND fechaemision <= rfiltros.fechahasta )
			AND centro=99-- AND nrofactura = 98651
			AND nrosucursal=20
			--AND tipocomprobante=1
		ORDER BY fechaventa,nrofactura
	) as resumenfacturacion 
	

);
  

return true;
END;
$function$
