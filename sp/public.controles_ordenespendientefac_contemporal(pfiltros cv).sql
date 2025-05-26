CREATE OR REPLACE FUNCTION public.controles_ordenespendientefac_contemporal(pfiltros character varying)
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
CREATE TEMP TABLE temp_controles_ordenesPendienteFac_contemporal
AS (
	SELECT *,
	  --,'1-Edad#edad@2-Nombres#nombres@3-Apellido#apellido@4-Nrodoc#nrodoc@5-Nomenclador#idsubespecialidad@6-Capitulo#idcapitulo@7-SubCapitulo#idsubcapitulo@8-Practica#idpractica@4-Nombre#pdescripcion@4-Plan Cobertura#descripcion@4-Centro Regional#cregional@4-Asoc.#acdecripcion@4-Importe#importe@4-Cantidad#cantidad'::text as mapeocampocolumna 
	  '1-idrecibo#idrecibo@2-centro#centro@3-NroRecibo#elidrecibo@4-nroorden#nroorden@5-NroOrden#elidorden@6-Afiliado#elafiliado@7-Diagnostico#diagnostico@8-Prestador#acdecripcion@9-NroDoc#nrodoc@10-tipodoc#tipodoc@11-Fecha Emision#fechaemision@12-Importe A Cargo del Afiliado#importe@13-descripcion#fpdescripcion@14-Total Orden#total'::text as mapeocampocolumna 
	FROM (
			SELECT
		--importesorden.* as io,

		 idrecibo,centro,CONCAT(idrecibo,'-',centro) AS elidrecibo, 
		nroorden, CONCAT(nroorden,'-',centro) AS elidorden, CONCAT(apellido, ', ', nombres) as elafiliado,
		diagnostico, acdecripcion, consumo.nrodoc, consumo.tipodoc  , to_char(fechaemision, 'DD/MM/YYYY hh:mm:ss') as fechaemision 

		,importe, fpdescripcion, t1.total as Total

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
                left join (
 SELECT nroorden, centro, round(sum(importe)::numeric,2)::float as total
		
FROM ordenrecibo
		NATURAL JOIN consumo
		NATURAL JOIN orden
		NATURAL JOIN cambioestadosorden

		NATURAL JOIN ordvalorizada 

		NATURAL JOIN (SELECT DISTINCT idasocconv,acdecripcion FROM  asocconvenio WHERE acactivo AND aconline and idasocconv=127) as asocconvenio 
                 NATURAL JOIN persona     
                LEFT JOIN ( SELECT nroorden, centro FROM itemvalorizada NATURAL JOIN iteminformacion WHERE iditemestadotipo=1 GROUP BY nroorden, centro) as t USING(nroorden, centro)

		left join importesorden using( nroorden, centro)
		
		WHERE idordenventaestadotipo= 1
		 AND nullvalue(ceofechafin) 
		 AND tipo=56
		 AND nullvalue(t.nroorden) AND true  AND  barra <100 

group by nroorden,centro




                    ) as t1 using (nroorden, centro)

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
