CREATE OR REPLACE FUNCTION public.auditoriaprestaciones(bigint, integer)
 RETURNS TABLE(nroorden bigint, centro integer, imp_fmpaiimportes double precision, imp_fmpaiimporteiva double precision, imp_fmpaiimportetotal double precision, imp_fmpaimportedebito double precision, observacion character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
         tipomov varchar;
BEGIN
/**
***  LEERR !!! Si se desea realizar cualquier modificacion se debe eliminar la funcion y volver a crear.  ***
***  Modificar Solo usando PgAdmin3
*/
	 RETURN QUERY SELECT  T.nroorden:: bigint, 
		T.centro:: integer, 
		SUM(fmpaiimportes):: double precision as imp_fmpaiimportes,
		SUM(fmpaiimporteiva):: double precision as imp_fmpaiimporteiva, 
		SUM(fmpaiimportetotal):: double precision as imp_fmpaiimportetotal,
		SUM(fmpaimportedebito):: double precision as imp_fmpaimportedebito, 
		'Obs.':: character varying as observacion
	FROM (SELECT * FROM obtenerdatosfichamedicaauditada($1,$2, null ,'A','A',null) WHERE true ) AS T
	NATURAL JOIN fichamedicapreauditada
	WHERE T.nroorden = $1 and T.centro = $2
	GROUP BY T.nroorden,T.centro;
  
END
$function$
