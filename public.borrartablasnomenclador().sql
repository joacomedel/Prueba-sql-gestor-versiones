CREATE OR REPLACE FUNCTION public.borrartablasnomenclador()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

	resultado 	boolean;

BEGIN
	resultado = true;

	DELETE FROM nomencladoruno;
	DELETE FROM nomencladordos;
	DELETE FROM practica;
	DELETE FROM subcapitulo;
	DELETE FROM capitulo;
	DELETE FROM nomenclador;

	DELETE FROM tempnomencladoruno;
	DELETE FROM tempnomencladordos;
	DELETE FROM tempsubcapitulo;
	DELETE FROM tempcapitulo;
	DELETE FROM tempnomenclador;


	return resultado;
END;
$function$
