CREATE OR REPLACE FUNCTION public.agregarnomencladores()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

	resultado 	boolean;

BEGIN
--	SELECT INTO resultado * FROM amnomenclador();
--	SELECT INTO resultado * FROM amcapitulo();
--	SELECT INTO resultado * FROM amsubcapitulo();
	SELECT INTO resultado * FROM amnomencladoruno();
--	SELECT INTO resultado * FROM amnomencladordos();


	
	return resultado;
END;
$function$
