CREATE OR REPLACE FUNCTION public.controles_ordenespendientefac_contemporal()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

--EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

-- GK 16-05-2022 - Agrego fecha facturación
-- GK 17-10-2022 - Cambios solicitados por usuario importe total / unitario y diferentes cobertueas
CREATE TEMP TABLE temp_controles_ordenesPendienteFac_contemporal
AS (
	SELECT *
	  --,'1-Edad#edad@2-Nombres#nombres@3-Apellido#apellido@4-Nrodoc#nrodoc@5-Nomenclador#idsubespecialidad@6-Capitulo#idcapitulo@7-SubCapitulo#idsubcapitulo@8-Practica#idpractica@4-Nombre#pdescripcion@4-Plan Cobertura#descripcion@4-Centro Regional#cregional@4-Asoc.#acdecripcion@4-Importe#importe@4-Cantidad#cantidad'::text as mapeocampocolumna 
	  --'1-Factura#factura@2-Nro Orden#nroorden@3-Fecha Facturacion#fechaventa@4-Cliente#nombreapellido@5-Nro Doc#nrodoc@6-Descripcion#descripcion@7-Cod Barra#mcodbarra@8-Cant. VendidaS#cantidad@9-Imp Unitoraio#importeunitario@10-Importe Totalc#total'::text as mapeocampocolumna 
	FROM (
			SELECT
		--importesorden.* as io,

		 idrecibo,centro,CONCAT(idrecibo,'-',centro) AS elidrecibo, 
		nroorden, centro, CONCAT(nroorden,'-',centro) AS elidorden, CONCAT(apellido, ', ', nombres) as elafiliado,
		diagnostico, acdecripcion, consumo.nrodoc, consumo.tipodoc  , to_char(fechaemision, 'DD/MM/YYYY hh:mm:ss') as fechaemision 

		,importe, fpdescripcion

		FROM ordenrecibo
		NATURAL JOIN consumo
		NATURAL JOIN orden
		NATURAL JOIN cambioestadosorden
		NATURAL JOIN ordenonlineinfoextra 
		NATURAL JOIN ordvalorizada 
		JOIN prestador ON (nromatricula = idprestador)
		NATURAL JOIN (SELECT DISTINCT idasocconv,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline and idasocconv=127) as asocconvenio NATURAL JOIN persona     LEFT JOIN ( SELECT nroorden, centro FROM itemvalorizada NATURAL JOIN iteminformacion WHERE iditemestadotipo=1 GROUP BY nroorden, centro) as t USING(nroorden, centro)

		left join importesorden using( nroorden, centro)
		--left join recibo using (idrecibo, centro)
		left join formapagotipos using(idformapagotipos)
		WHERE idordenventaestadotipo= 1
		 AND nullvalue(ceofechafin) 
		 AND tipo=56
		 AND nullvalue(t.nroorden) AND true  AND  barra <100 
		 AND idformapagotipos  = 3
		ORDER BY nroorden, fechaemision
	) as ordenes 
	

);
  

return true;
END;
$function$
