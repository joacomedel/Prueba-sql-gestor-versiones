CREATE OR REPLACE FUNCTION public.afiliadospormonodrogaconsumida_contemporal(monodrogas character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
rmonodrogas record;
monodrogasNombres text[];
monodrogaNombreActual  varchar;    
resultadoConsulta record;
limiteInferiorDias varchar;

BEGIN
EXECUTE sys_dar_filtros(monodrogas) INTO rmonodrogas;
SELECT string_to_array(rmonodrogas.monodrogas,'-') INTO monodrogasNombres;
limiteInferiorDias := CAST(rmonodrogas.limiteInferiorDias AS VARCHAR(255))||' days' ;
RAISE NOTICE '%',limiteInferiorDias;

--En esta tabla se carga todos los afiliados para cada monodroga
CREATE TEMP TABLE temp_afiliadospormonodrogaconsumida_contemporal_sinordenar (afiliado TEXT,nro_afiliado TEXT,monodroga TEXT,fecha_registrada DATE,unidad text,importe_total float);                    

--Lo misma tabla que arriba, pero ordenada
CREATE TEMP TABLE temp_afiliadospormonodrogaconsumida_contemporal (afiliado TEXT,nro_afiliado TEXT,monodroga TEXT,fecha_registrada DATE,unidad text,importe_total float);                 

--Se carga la tabla desordenada
FOREACH monodrogaNombreActual IN ARRAY monodrogasNombres LOOP
    INSERT INTO temp_afiliadospormonodrogaconsumida_contemporal_sinordenar
    /*SELECT concat(nombres,' ',apellido) as afiliado,concat('DNI:',persona.nrodoc,'/',persona.barra) as nroafiliado,
	concat(monnombre,' - ',mpresentacion) as monodroga,fechaemision,importeapagar,fimportetotal
    
	FROM 
        recetario
	    JOIN persona USING(nrodoc,tipodoc) 
        JOIN recetarioitem USING (nrorecetario)
        JOIN medicamento USING (mnroregistro)
        JOIN manextra USING (mnroregistro)
        JOIN monodroga USING (idmonodroga)
		JOIN factura as fac USING(nroregistro,anio) 
    WHERE
        monodroga.monnombre ilike '%'||monodrogaNombreActual||'%' and 
        fechaemision >= CURRENT_DATE - limiteInferiorDias::INTERVAL
   GROUP BY
        afiliado,idmonodroga,monnombre,nroafiliado,mpresentacion,fechaemision,importeapagar,fimportetotal;*/
	SELECT UPPER(aapellidoynombre) as afiliado,concat('DNI:',fa.nrodoc,'/',fa.barra) as nroafiliado,
	concat(monnombre,' - ',mpresentacion) as monodroga,fechaemision,concat(oviprecioventa,' x ',ovicantidad) as importeunitario,
	(oviprecioventa*ovicantidad) as importetotal
	FROM 
		far_ordenventareceta
		NATURAL JOIN far_ordenventa 
		NATURAL JOIN far_ordenventaitem 
		NATURAL JOIN far_articulo
		LEFT JOIN far_medicamento USING (idarticulo 	,idcentroarticulo)
		LEFT JOIN manextra USING (mnroregistro)
		LEFT JOIN medicamento USING (mnroregistro)
		LEFT JOIN monodroga USING (idmonodroga)
		NATURAL JOIN far_ordenventaitemimportes as far_ordimp
		LEFT JOIN far_ordenventaitemitemfacturaventa USING (idordenventaitem,idcentroordenventaitem)
		LEFT JOIN facturaventa USING (nrofactura,nrosucursal,tipocomprobante,tipofactura)
		LEFT JOIN far_afiliado as fa ON far_ordimp.oviiidobrasocial = fa.idobrasocial AND far_ordimp.oviitipodoc = fa.tipodoc AND far_ordimp.oviinrodoc = fa.nrodoc 

	WHERE
        monodroga.monnombre ilike '%'||monodrogaNombreActual||'%' and 
        fechaemision >= CURRENT_DATE - limiteInferiorDias::INTERVAL 
		and fa.nrodoc IS NOT NULL
   GROUP BY
        afiliado,idmonodroga,monnombre,nroafiliado,mpresentacion,fechaemision,importeunitario,importetotal,ovicantidad;
		
END LOOP;

	--Se carga la tabla ordenada
	INSERT INTO temp_afiliadospormonodrogaconsumida_contemporal
    SELECT * FROM temp_afiliadospormonodrogaconsumida_contemporal_sinordenar ORDER BY nro_afiliado;

return true;
END;
$function$
