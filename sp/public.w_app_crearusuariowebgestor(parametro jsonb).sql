CREATE OR REPLACE FUNCTION public.w_app_crearusuariowebgestor(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ 

/*ds 06/03/24 - creo SP para crear un usuario gestor de prestadores
select from w_app_crearusuariowebgestor('{"uwnombreweb":"ClinicaSosuncPrueba",
					  "uwcontraseniaweb":"prueba@123",
					  "uwgdescripcionweb":"Clinica Sosunc Prueba",
					  "uwprovincia":"Neuquen",
					  "uwlocalidad":"Neuquen",
					  "dbarrio":" ",
					  "dcalle":"Buenos Aires", 
					  "dnro":"1400",
					  "uwmailweb":"darianagsm@gmail.com" }';*/

DECLARE 
    idusuariosecuencia integer;
	iddireccionsecuencia integer;
    uwnombreweb varchar;
	uwcontraseniaweb varchar;
    uwmailweb varchar;
    uwgdescripcionweb varchar;
    uwprovincia varchar;
    uwlocalidad varchar;
    idprovinciaencontrada integer;
	idlocalidadencontrada integer;
	iddireccionencontrada integer;
	wusuario RECORD;
BEGIN	
	uwnombreweb = parametro->>'uwnombreweb';
	uwcontraseniaweb = parametro->>'uwcontraseniaweb';
	uwmailweb = parametro->>'uwmailweb';
    uwgdescripcionweb = parametro->>'uwgdescripcionweb';
    uwprovincia = parametro->>'uwprovincia';
    uwlocalidad = parametro->>'uwlocalidad';
	
    SELECT idprovincia INTO idprovinciaencontrada FROM provincia WHERE REPLACE(lower(descrip), ' ', '') = REPLACE(lower(uwprovincia), ' ', '');

	IF idprovinciaencontrada IS NULL THEN
    	RAISE EXCEPTION 'No se encontró una provincia con esa descripción registrada "%".', uwprovincia;
	END IF;

	SELECT idlocalidad INTO idlocalidadencontrada FROM localidad WHERE REPLACE(lower(descrip), ' ', '') = REPLACE(lower(uwlocalidad), ' ', '');

	IF idlocalidadencontrada IS NULL THEN
    	RAISE EXCEPTION 'No se encontró una localidad con esa descripción registrada "%".', uwlocalidad;
	END IF;    

	SELECT iddireccion INTO iddireccionencontrada FROM direccion WHERE lower(trim(barrio)) = lower(trim(parametro->>'dbarrio')) AND lower(trim(calle)) = lower(trim(parametro->>'dcalle')) AND trim(nro) = trim(parametro->>'dnro') AND idprovincia = idprovinciaencontrada AND idlocalidad = idlocalidadencontrada;

	IF iddireccionencontrada IS NULL THEN 
		INSERT INTO direccion (barrio, calle, nro, idprovincia, idlocalidad, idcentrodireccion) VALUES (parametro->>'dbarrio', parametro->>'dcalle', CAST(parametro->>'dnro' AS INTEGER), idprovinciaencontrada, idlocalidadencontrada, 1)
		RETURNING iddireccion INTO iddireccionencontrada;
	END IF;

	INSERT INTO w_usuarioweb (uwnombre, uwcontrasenia, uwmail, uwsuscripcionnl, uwactivo, uwtipo) VALUES (uwnombreweb, md5(uwcontraseniaweb), uwmailweb, true, true, 4)
	RETURNING idusuarioweb INTO idusuariosecuencia;

	INSERT INTO w_usuariowebgestor (idusuarioweb, uwgdescripcion, iddireccion, idcentrodireccion) VALUES (idusuariosecuencia, uwgdescripcionweb, iddireccionencontrada, 1);
	
	INSERT INTO w_usuariorolweb (idusuarioweb, idrolweb) values (idusuariosecuencia, 28); 

	SELECT uwnombre, uwmail, uwemailverificado
	INTO wusuario
	FROM w_usuarioweb as uw
	WHERE idusuarioweb = idusuariosecuencia;

RETURN jsonb_build_object('wusuario', wusuario);
	
END;

$function$
