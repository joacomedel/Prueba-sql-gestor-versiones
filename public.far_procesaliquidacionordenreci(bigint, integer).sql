CREATE OR REPLACE FUNCTION public.far_procesaliquidacionordenreci(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--record
	--existere RECORD;
	rovla RECORD;

      
BEGIN
  
     SELECT INTO rovla * FROM far_ordenventaliquidacionauditada 
     WHERE not ovlaprocesado AND nroregistro=$1 AND  anio = $2; 
/*se procesaron todas las ordenes entonces ahora puedo ver si corresponde insertarlas en la tabla*/
     IF NOT FOUND THEN 
           INSERT INTO ordenreciprocidadpreauditada (nroorden,anio,nroregistro,centro,idcomprobantetipos,barra,idosreci)
		SELECT DISTINCT recitemporal.nroorden, recitemporal.anio, recitemporal.nroregistro,recitemporal.centro 
                , tipo,AA.barra,AA.idosreci 
		FROM (SELECT P.nrodoc, P.tipodoc,P.nroorden, P.centro, ordenesutilizadas.tipo, nroregistro, anio,nroordenpago,fechauso 
		FROM factura  JOIN facturaordenesutilizadas USING(nroregistro, anio) 
		JOIN ordenesutilizadas USING(nroorden, centro,tipo) JOIN 
		(SELECT fichamedica.nrodoc, fichamedica.tipodoc,T.nroorden, T.centro, tipo 
		FROM  fichamedica JOIN fichamedicapreauditada USING(idfichamedica, idcentrofichamedica) 
		JOIN  (SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
		FROM  fichamedicapreauditadaitemconsulta 
		UNION 
		SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
		FROM fichamedicapreauditadaitem NATURAL JOIN itemvalorizada ) as T 
		USING(idfichamedicapreauditada, idcentrofichamedicapreauditada) ) AS P USING(nroorden,centro,tipo) 
		UNION 
		SELECT r.nrodoc, r.tipodoc, r.nrorecetario as nroorden, r.centro, CASE WHEN nullvalue(rtp.nrorecetario) THEN 14 ELSE 37 END as tipo
		,nroregistro, anio, nroordenpago ,fechauso 
		FROM factura JOIN recetario as r USING(nroregistro,anio) LEFT JOIN recetariotp as rtp  ON(r.nrorecetario=rtp.nrorecetario 
                AND r.centro=rtp.centro) ) AS recitemporal 	NATURAL JOIN persona JOIN 
		( SELECT osreci.barra,descrip,idosreci, nrodoc, tipodoc, abreviatura FROM osreci JOIN afilreci USING(idosreci,barra)
		UNION 
		SELECT osreci.barra,descrip,idosreci, benefreci.nrodoc, benefreci.tipodoc, abreviatura 
		FROM osreci  JOIN afilreci  USING(idosreci,barra) 
		JOIN benefreci ON (nrodoctitu = afilreci.nrodoc AND tipodoctitu = afilreci.tipodoc) ) AS AA USING(nrodoc, tipodoc) 
                JOIN histobarras USING(nrodoc, tipodoc)
                LEFT JOIN ordenreciprocidadpreauditada AS orpa 
                ON (recitemporal.nroorden=orpa.nroorden AND recitemporal.centro=orpa.centro AND tipo=idcomprobantetipos)
		WHERE recitemporal.nroregistro=$1 AND  recitemporal.anio = $2 AND (cast(histobarras.fechaini as date)<= fechauso) 
               AND (cast(histobarras.fechafin as date)>= fechauso) AND histobarras.barra>=100 
               AND nullvalue(orpa.nroorden);	 
	END IF;
return 	true;
END;
$function$
