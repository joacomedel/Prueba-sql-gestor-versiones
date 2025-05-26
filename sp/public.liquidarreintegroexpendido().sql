CREATE OR REPLACE FUNCTION public.liquidarreintegroexpendido()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
	elreintegro RECORD;
	relbeneficiario RECORD;
	laotp RECORD;

--variables 
	idnroop INTEGER;
BEGIN

	PERFORM modificarprestacionreintegro();
        SELECT INTO elreintegro * FROM tempreintegromodificado;
	INSERT INTO restados
                 (fechacambio,nroreintegro,tipoestadoreintegro,anio,observacion,idcentroregional)
                 VALUES(NOW(),elreintegro.nroreintegro,2,elreintegro.anio,'Generado desde el expendio-reintegro',elreintegro.idcentroregional);

	
return true;   

END;
$function$
