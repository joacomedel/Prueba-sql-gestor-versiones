CREATE OR REPLACE FUNCTION public.controles_consumofarmaciaprestador_contemporal(pfiltros character varying)
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
CREATE TEMP TABLE temp_controles_consumofarmaciaprestador_contemporal
AS (
	SELECT *,
	  --,'1-Edad#edad@2-Nombres#nombres@3-Apellido#apellido@4-Nrodoc#nrodoc@5-Nomenclador#idsubespecialidad@6-Capitulo#idcapitulo@7-SubCapitulo#idsubcapitulo@8-Practica#idpractica@4-Nombre#pdescripcion@4-Plan Cobertura#descripcion@4-Centro Regional#cregional@4-Asoc.#acdecripcion@4-Importe#importe@4-Cantidad#cantidad'::text as mapeocampocolumna 
	     '1-Fecha Venta#fechaventa@2-Medicamento#monnombre@3-Droga#mnombre@4-Precio unitario#importeunitario@5-Cantidad#cantidad@6-Total#total@7-OOSS#osdescripcion@8-% OOSS#cobseguro@9-Cobertura OOSS ($)#importecobertura@10-% Reintegro Sosunc#cobcoseguro@11-Reintregro Sosunc ($)#importecoseguro@12-nrorecetario#nrorecetario@13-idmonodroga#idmonodroga@14-nombreapellido#nombreapellido@15-mcodbarra#mcodbarra@16-pdescripcion#pdescripcion'::text as mapeocampocolumna 
	     FROM (
	     	/*
					SELECT  concat('000',recetario.centro,nrorecetario)  as nrorecetario, 
									fechauso,
									fechauso as fechaventa,
									concat (monnombre,'  -  ',mpresentacion) as monnombre,
									idmonodroga,
									mnombre,
									importe as importecoseguro,
									importe as importecobertura,
									concat(apellido,', ',nombres) as nombreapellido,
									mcodbarra,
									gratuito,
									coberturaporplan,
									coberturaefectiva,
									prestador.idprestador,
									prestador.pdescripcion,
									0 as cantidad,

									coberturaporplan as cobcoseguro,
									coberturaefectiva as cobseguro,


									importevigente as importeunitario,
									importevigente as total,
									"SIn cargar" as osdescripcion

					FROM recetario
					JOIN persona USING(nrodoc,tipodoc)
					JOIN recetarioitem USING (nrorecetario)
					JOIN medicamento USING (mnroregistro)
					JOIN manextra USING (mnroregistro)
					JOIN monodroga USING (idmonodroga)
					JOIN factura USING(nroregistro,anio)
					JOIN prestador ON factura.idprestador = prestador.idprestador
					WHERE not nullvalue(fechauso)
								AND ( nrodoc = rfiltros.nrodoc OR nullvalue(rfiltros.nrodoc))
								AND (fechauso >= rfiltros.fechadesde AND fechauso <= rfiltros.fechahasta)
								AND factura.idprestador <> 2608 --Quito los consumo de la farmacia de sosunc pues los reporte por otro lado
	UNION */

					SELECT 
						
						concat(far_ordenventareceta.centro,nrorecetario,' OV ',idordenventa,'-',idcentroordenventa)  as nrorecetario,
						CASE WHEN nullvalue(ovrfechauso) THEN ovfechaemision ELSE ovrfechauso END as fechauso,
						fechaemision as fechaventa,
						concat (monnombre,'  -  ',mpresentacion) as monnombre,
						idmonodroga,
						adescripcion as mnombre,

						fovii.oviimonto as importecoseguro,
						cobertura.oviimonto as importecobertura,
						
						aapellidoynombre as nombreapellido,
						acodigobarra as mcodbarra,
						false as gratuito,

						fovii.oviiporcentajecobertura as coberturaporplan,
						fovii.oviiporcentajecobertura as coberturaefectiva,
						prestador.idprestador,
						prestador.pdescripcion,
						ovicantidad as cantidad,

						fovii.oviiporcentajecobertura  as cobcoseguro,
						cobertura.oviiporcentajecobertura as cobseguro,

						oviprecioventa as importeunitario,
						(oviprecioventa*ovicantidad) as total,
						osdescripcion

					FROM far_ordenventareceta
					NATURAL JOIN far_ordenventa 
					NATURAL JOIN far_ordenventaitem 
					NATURAL JOIN far_articulo
					--NATURAL JOIN far_medicamento
					LEFT JOIN far_medicamento USING (idarticulo 	,idcentroarticulo)
					LEFT JOIN manextra USING (mnroregistro)
					LEFT JOIN medicamento USING (mnroregistro)
					LEFT JOIN monodroga USING (idmonodroga)
					NATURAL JOIN far_ordenventaitemimportes as fovii
					LEFT JOIN (SELECT * FROM far_ordenventaitemimportes WHERE idvalorescaja != 63 AND idvalorescaja != 61 AND idvalorescaja != 0) as cobertura USING (idordenventaitem,idcentroordenventaitem)
					LEFT JOIN far_ordenventaitemitemfacturaventa USING (idordenventaitem,idcentroordenventaitem)
					LEFT JOIN facturaventa USING (nrofactura,nrosucursal,tipocomprobante,tipofactura)
					JOIN prestador ON prestador.idprestador = 2608
					LEFT JOIN far_afiliado as fa ON fovii.oviiidobrasocial = fa.idobrasocial AND fovii.oviitipodoc = fa.tipodoc AND fovii.oviinrodoc = fa.nrodoc 
					LEFT JOIN far_obrasocial as fo ON(fo.idobrasocial=  cobertura.oviiidobrasocial)

					WHERE 
					(fovii.idvalorescaja = 63 OR  fovii.idvalorescaja = 59) AND 
						(ovfechaemision >= rfiltros.fechadesde AND ovfechaemision <= rfiltros.fechahasta )
					AND ( fa.nrodoc = rfiltros.nrodoc OR nullvalue(rfiltros.nrodoc))
AND nullvalue(anulada)
				--AND (tipodoc = $P{tipodoc} OR $P{tipodoc} = 0)

	) as consumofarmacia

	ORDER BY fechauso

	

);
  

return true;
END;
$function$
