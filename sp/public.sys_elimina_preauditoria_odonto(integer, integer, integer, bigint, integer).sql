CREATE OR REPLACE FUNCTION public.sys_elimina_preauditoria_odonto(integer, integer, integer, bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  pnroorden ALIAS FOR $1;
  pcentro ALIAS FOR $2;
  ptipo ALIAS FOR $3;
  pnrooregistro ALIAS FOR $4;
  panio ALIAS FOR $5;
  respuesta BOOLEAN;
  simportepagar float;
  elem RECORD;
  
 
BEGIN

respuesta = true;
SELECT INTO elem * FROM facturaordenesutilizadas 
	WHERE nroorden = pnroorden AND centro = pcentro and tipo=ptipo 
	AND nroregistro = pnrooregistro
	AND anio = panio
	 LIMIT 1;
IF FOUND THEN  -- Solo la elimino si esa orden apunta a ese nro de registro

	DELETE FROM facturaordenesutilizadas 
	       WHERE nroorden = pnroorden AND centro = pcentro AND tipo= ptipo;

	DELETE FROM ordenesutilizadas 
	       WHERE nroorden = pnroorden AND centro = pcentro AND tipo= ptipo;


	SELECT INTO simportepagar sum(importe)   FROM facturaordenesutilizadas 
						    NATURAL JOIN ordenesutilizadas
						    WHERE anio =elem.anio AND nroregistro =elem.nroregistro;
	UPDATE factura SET fimportepagar = simportepagar 
		       WHERE anio = elem.anio AND nroregistro =elem.nroregistro; 

	DELETE FROM fichamedicapreauditadaodonto 
	 WHERE (idfichamedicapreauditada,idcentrofichamedicapreauditada) IN (
	   SELECT idfichamedicapreauditada,idcentrofichamedicapreauditada
	   FROM fichamedicapreauditadaitem
	   NATURAL JOIN itemvalorizada
	   NATURAL JOIN item
	   WHERE nroorden = pnroorden AND centro = pcentro

	   );



	DELETE FROM fichamedicapreauditada 
	 WHERE (idfichamedicapreauditada,idcentrofichamedicapreauditada) IN (
	   SELECT idfichamedicapreauditada,idcentrofichamedicapreauditada
	   FROM fichamedicapreauditadaitem
	   NATURAL JOIN itemvalorizada
	   NATURAL JOIN item
	   WHERE nroorden = pnroorden AND centro = pcentro 

	   );
	   
	--DELETE FROM fichamedicapreauditadaitem  WHERE iditem  = 152965

	DELETE FROM fichamedicapreauditadaitem 
	    WHERE (iditem,centro) IN (
	    SELECT iditem,centro FROM itemvalorizada
	    NATURAL JOIN item
	    WHERE nroorden = pnroorden AND centro = pcentro
	);
	  

	IF ptipo=4 THEN

	     DELETE FROM fichamedicapreauditadaitemconsulta 
		      WHERE nroorden = pnroorden AND centro = pcentro;

	ELSE 
	    DELETE FROM fichamedicapreauditadaitemrecetario 
	    WHERE (idrecetarioitem,centro) IN (
	    SELECT idrecetarioitem,centro FROM fichamedicapreauditadaitemrecetario
	    NATURAL JOIN recetarioitem
	    WHERE nrorecetario = pnroorden AND centro = pcentro );

	    DELETE FROM recetarioitem 
	    WHERE nrorecetario = pnroorden AND centro = pcentro;

	    UPDATE recetario SET nrodoc=null, tipodoc=null, nroregistro = null, anio=null 
	   WHERE nrorecetario=pnroorden AND centro = pcentro;


	END IF;
END IF;

return respuesta;

END;$function$
