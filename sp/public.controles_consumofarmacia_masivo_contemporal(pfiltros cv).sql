CREATE OR REPLACE FUNCTION public.controles_consumofarmacia_masivo_contemporal(pfiltros character varying)
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
--Para obtener el consumo de Observer
PERFORM FROM consumos_afiliado_sigesobserver_contemporal(null); 
--SELECT * FROM temp_consumos_afiliado_sigesobserver_contemporal;

CREATE TEMP TABLE temp_controles_consumofarmacia_masivo_contemporal
AS (
	SELECT *,
	  --,'1-Edad#edad@2-Nombres#nombres@3-Apellido#apellido@4-Nrodoc#nrodoc@5-Nomenclador#idsubespecialidad@6-Capitulo#idcapitulo@7-SubCapitulo#idsubcapitulo@8-Practica#idpractica@4-Nombre#pdescripcion@4-Plan Cobertura#descripcion@4-Centro Regional#cregional@4-Asoc.#acdecripcion@4-Importe#importe@4-Cantidad#cantidad'::text as mapeocampocolumna 
  	     '1-Fecha Venta#fechaventa@2-Medicamento#mnombre@3-idmonodroga#idmonodroga@4-Droga#monnombre@5-Precio unitario#importeunitario@6-Cantidad#cantidad@7-Total#total@8-OOSS#osdescripcion@9-% OOSS#cobseguro@10-Cobertura OOSS ($)#importecobertura@11-% Reintegro Sosunc#cobcoseguro@12-Reintregro Sosunc ($)#importecoseguro@13-nombreapellido#nombreapellido@14-Nro afiliado#nroafiliado@15-cod barra producto#mcodbarra@16-Nro recetario#nrorecetario@17-Prescriptor#pdescripcion@18-Farmacia#farmacia@19-Nro titular OS#titular@19-TipoVenta#ftvdescripcion'::text as mapeocampocolumna 


	FROM (
	     	
					SELECT  concat('000',recetario.centro,nrorecetario)  as nrorecetario, 
									fechauso,
									fechauso as fechaventa,
									concat (monnombre,'  -  ',mpresentacion) as monnombre,
									idmonodroga,
									mnombre,
									importe as importecoseguro,
									importe as importecobertura,
									concat(persona.apellido,', ',persona.nombres) as nombreapellido,
			                        concat('DNI:',persona.nrodoc,'/',persona.barra) as nroafiliado,
                                                CASE WHEN not nullvalue(bs.nrodoc) THEN  concat('DNI:',ts.nrodoc,'/',ts.barra)
                                                     WHEN not nullvalue(br.nrodoc) THEN  concat('DNI:',tr.nrodoc,'/',tr.barra) 
                                                     ELSE  concat('DNI:',persona.nrodoc,'/',persona.barra)   END as titular,
									mcodbarra,
									gratuito,
									coberturaporplan,
									coberturaefectiva,
									prestador.idprestador,
									prestador.pdescripcion,
                                                                        f.pdescripcion as farmacia,
									1 as cantidad,
									coberturaporplan as cobcoseguro,
									coberturaefectiva as cobseguro,
									importevigente as importeunitario,
									importevigente as total,
									'Sosunc - Externo' as osdescripcion,
                                                                        ftvdescripcion
					FROM recetario
                                        LEFT JOIN prestador as f ON(recetario.idfarmacia =f.idprestador) 
					JOIN persona USING(nrodoc,tipodoc)
                                        LEFT JOIN benefsosunc bs ON (bs.nrodoc = persona.nrodoc)  -- analiso si es un beneficiario y busco altitular
                                        LEFT JOIN persona  ts ON (ts.nrodoc = bs.nrodoctitu) --- titular del benef sosunc

                                        LEFT JOIN benefreci br ON (br.nrodoc = persona.nrodoc)   -- analizo si es un beneficiario y busco al titular
                                        LEFT JOIN persona  tr ON (tr.nrodoc = br.nrodoctitu) --- titular del benef sosunc

			                JOIN recetarioitem USING (nrorecetario)
					JOIN medicamento USING (mnroregistro)
                                        join  farmtipoventa using(idfarmtipoventa)
					JOIN manextra USING (mnroregistro)
					JOIN monodroga USING (idmonodroga)
					JOIN factura USING(nroregistro,anio)
					JOIN prestador ON factura.idprestador = prestador.idprestador
					WHERE not nullvalue(fechauso)
								AND (fechauso >= rfiltros.fechadesde AND fechauso <= rfiltros.fechahasta)
								AND factura.idprestador <> 2608 

                                                           AND(idfarmtipoventa=rfiltros.idfarmtipoventa or NULLVALUE(rfiltros.idfarmtipoventa))

--Quito los consumo de la farmacia de sosunc pues los reporte por otro lado
	UNION 

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
			                        concat('DNI:',p.nrodoc,'/',p.barra) as nroafiliado,
                                                 
                                                concat('DNI:',c.nrodoc,'/',c.barra) as titular,
						acodigobarra as mcodbarra,
						false as gratuito,
						fovii.oviiporcentajecobertura as coberturaporplan,
						fovii.oviiporcentajecobertura as coberturaefectiva,
						prestador.idprestador,
						prestador.pdescripcion,
                                                'FARM. UNIV.' as farmacia,
						ovicantidad as cantidad,
						fovii.oviiporcentajecobertura  as cobcoseguro,
						cobertura.oviiporcentajecobertura as cobseguro,
						oviprecioventa as importeunitario,
						(oviprecioventa*ovicantidad) as total,
						osdescripcion,
                                                ftvdescripcion

					FROM far_ordenventareceta
					NATURAL JOIN far_ordenventa 
					NATURAL JOIN far_ordenventaitem 
					NATURAL JOIN far_articulo
                                        NATURAL JOIN far_ordenventaestado 
					--NATURAL JOIN far_medicamento
					LEFT JOIN far_medicamento USING (idarticulo 	,idcentroarticulo)
					LEFT JOIN manextra USING (mnroregistro)
					LEFT JOIN medicamento USING (mnroregistro)
                                        LEFT join  farmtipoventa using(idfarmtipoventa)
					LEFT JOIN monodroga USING (idmonodroga)
					NATURAL JOIN far_ordenventaitemimportes as fovii
					LEFT JOIN (SELECT * FROM far_ordenventaitemimportes WHERE idvalorescaja != 63 AND idvalorescaja != 61 AND idvalorescaja != 0) as cobertura USING (idordenventaitem,idcentroordenventaitem)
					LEFT JOIN far_ordenventaitemitemfacturaventa USING (idordenventaitem,idcentroordenventaitem)
					LEFT JOIN facturaventa USING (nrofactura,nrosucursal,tipocomprobante,tipofactura)
					LEFT JOIN prestador ON prestador.idprestador = far_ordenventareceta.idprestador
					JOIN far_afiliado as fa ON fovii.oviiidobrasocial = fa.idobrasocial AND fovii.oviitipodoc = fa.tipodoc AND fovii.oviinrodoc = fa.nrodoc 
					LEFT JOIN far_obrasocial as fo ON(fo.idobrasocial=  cobertura.oviiidobrasocial)
                                        LEFT JOIN persona p ON (fa.nrodoc=p.nrodoc)
                                        LEFT JOIN persona c ON (fa.nrocliente = c.nrodoc)
					WHERE (idordenventaestadotipo <> 2 AND nullvalue(ovefechafin)) AND
					(fovii.idvalorescaja = 63 OR  fovii.idvalorescaja = 59) AND 
						(ovfechaemision >= rfiltros.fechadesde AND ovfechaemision <= rfiltros.fechahasta )
					
AND nullvalue(anulada)
				
AND(idfarmtipoventa=rfiltros.idfarmtipoventa or NULLVALUE(rfiltros.idfarmtipoventa))
	) as consumofarmacia
---- WHERE   titular not ilike '%/35' AND  titular not ilike '%/36'  --- quito a jubilados y pensionados
	ORDER BY fechauso

	

);
  /*
  
  
  SELECT concat('Observer',idrecetaobserver) as nrorecetario
,rofechaprescripcion as fechauso
,rofechaventa as fechaventa
concat (monnombre,'  -  ',mpresentacion) as monnombre,
idmonodroga,
--adescripcion as mnombre,
 FROM "public"."recetaobserver"
 JOIN medicamento ON mcodbarra = rocodbarras
NATURAL JOIN (select concat(nrodoc,lpad(barra,3,'0')) as ronroafiliado,nrodoc,tipodoc
 from persona_consumo_medicamento natural join persona ) as persona
 WHERE rofechaprescripcion >= '2022-06-01'
  AND nullvalue(rocodigorechazo)
  AND roautorizada ilike 'S';

/*
ronroafiliado	idrecetaobserver	rofechaingreso	rofechaproceso	ronumeronodo	roopf	roidfarmacia	rofarmacia	rofechaprescripcion	rofechaventa	rofechasolicitud	rofechaanulacion	roautorizada	ronroreceta	rotipomatricula	romatricula	roimportereceta	roimporteos	roimporteafiliado	rocodigorechazo	romotivorechazo	rorenglon	rocodigoalfabeta	rotroquel	rocodbarras	rocantidad	ropvp	roprecioreferencia	roimporterenglon	roimporteosrenglon	roimporteafiliadorenglon	rocodrecrenglon	romotrechazorenglon	roidplan	roplan	ronombremedico	roporcentajecobertura	romontofijo	roidcontroldosisporafiliado	roidcontrolunidadesporafiliado	rocuit	idinformacionobserver	idcentroinformacionobserver	nrodoc	tipodoc
*/

/*

SELECT * FROM consumos_afiliado_rango_fecha_observer_siges_contemporal('{fechadesde=2021-12-01, afiliado=26805626, fechahasta=2022-12-31, cantidad=1}');
SELECT * FROM temp_consumos_afiliado_rango_fecha_observer_siges__contemporal

select concat(nrodoc,lpad(barra,3,'0')) as ronroafiliado,nrodoc,tipodoc
 from persona_consumo_medicamento natural join persona */

-------------------- GK ---------------------
Consumos
 SELECT 
                        extract(month from rofechaventa) as mes
                        ,extract(year from rofechaventa) as anio
                        ,nrodoc as afiliado
                        ,rofarmacia as expendio
                        ,rocodbarras as codigobarra
                        , concat(mnombre,' ',mpresentacion) as adescripcion
                        ,sum(rocantidad ) as cantidad
                    
                    FROM temp_consumos_afiliado_sigesobserver_contemporal
                    LEFT JOIN medicamentosys ON (rocodigoalfabeta=mnroregistro)
                    LEFT JOIN persona ON (SUBSTRING(ronroafiliado, 1, 8) = nrodoc)

                WHERE
                    rofechaventa>= rparam.fechadesde   
                    AND   rofechaventa<= rparam.fechahasta 
                    AND   roautorizada='S'
                GROUP BY afiliado,codigobarra,mes,anio,adescripcion,expendio
  
Anulaciones 

                SELECT 
                    extract(month from rofechaventa) as mes
                    ,extract(year from rofechaventa) as anio
                    ,nrodoc as afiliado 
                    ,rofarmacia as expendio
                    ,rocodbarras as codigobarra
                    --,adescripcion
                    ,sum(rocantidad ) as cantidad
                FROM temp_consumos_afiliado_sigesobserver_contemporal
                LEFT JOIN medicamentosys ON (rocodigoalfabeta=mnroregistro)
                LEFT JOIN persona ON (SUBSTRING(ronroafiliado, 1, 8) = nrodoc)

                WHERE
                  rofechaventa>= rparam.fechadesde   AND   rofechaventa  <= rparam.fechahasta
                  AND   roautorizada='N' AND NOT nullvalue(rofechaanulacion)
                GROUP BY codigobarra,afiliado,mes,anio,expendio
  */

return true;
END;
$function$
