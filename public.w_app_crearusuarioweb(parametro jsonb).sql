CREATE OR REPLACE FUNCTION public.w_app_crearusuarioweb(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
*	SELECT w_app_crearusuarioweb('{"accion": "afiliado", "pnrodoc": "43947118", "cantBenef": "0", "passMd5": "___", "passTrip": "___",usuario": "SebastianL", "fechaNac": "2002-02-10", "tipoCompr": "factura", "nroCompr": "123456"}');
*	SELECT w_app_crearusuarioweb('{"accion": "prestador", "cuit": "20-43947118-3","passMd5": "___", "usuario": "SebastianL", "tipoCompr": "ordPago", "nroCompr": "123456", "matricula": '5555'}');
*/
DECLARE
	respuestajson jsonb;
	vaccion varchar;
	rrespuesta character varying;
	rverif RECORD;
	rverifuser RECORD;
	rusuarioweb RECORD;
	rpersona RECORD;
	bverifica BOOLEAN;
	-- cantbenef INTEGER;
     jsoncadena varchar;
begin	 
	--Verifico que reciba todos los datos para operar
	IF (nullvalue(parametro->>'accion')) THEN
		RAISE EXCEPTION 'R-001, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
	END IF;

	vaccion = parametro->>'accion';
	bverifica = FALSE;

	CASE vaccion
		WHEN 'afiliado' THEN 
			IF (nullvalue(parametro->>'pnrodoc') OR nullvalue(parametro->>'cantBenef') 
			OR nullvalue(parametro->>'passMd5') OR nullvalue(parametro->>'passTrip')
			OR nullvalue(parametro->>'elusuario') OR nullvalue(parametro->>'fechaNac') 
            OR nullvalue(parametro->>'centro')  OR nullvalue(parametro->>'pemail') 
			OR nullvalue(parametro->>'tipoCompr') OR nullvalue(parametro->>'nroCompr')) THEN
				RAISE EXCEPTION 'R-002, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
			END IF;


			--Verifico la cantidad de benef y fecha de nacimiento
			--SELECT INTO cantbenef * --COUNT(*) AS cantbenef 
			SELECT INTO rpersona * --COUNT(*) AS cantbenef 
			FROM persona p 
				--LEFT JOIN benefsosunc b ON (b.nrodoctitu = p.nrodoc AND b.tipodoc = p.tipodoc)
				--LEFT JOIN benefreci br ON (br.nrodoctitu = p.nrodoc AND br.tipodoc = p.tipodoc)
				--LEFT JOIN persona pb ON ((pb.nrodoc = b.nrodoc OR pb.nrodoc = br.nrodoc) AND pb.fechafinos >= now())
			WHERE p.nrodoc = parametro->>'pnrodoc' 
			AND p.fechanac = parametro->>'fechaNac' 
			AND p.fechafinos >= now(); 
			--AND NOT nullvalue(pb.nrodoc);
			--SL 17/06/24 - Comento la confirmacion de benef ya que nadie le pega al dato :(
			IF FOUND  /* AND cantbenef = parametro->>'cantBenef' */ THEN
				-- Verifico que el usuario no exista
				SELECT INTO rverifuser * 
				FROM w_usuarioweb 
				WHERE uwnombre = parametro->>'elusuario'
				OR uwmail = parametro->>'pemail';
				
				IF FOUND THEN
					RAISE EXCEPTION 'R-008, El usuario/email ya existen';
				ELSE
					bverifica = TRUE;
				END IF;
			END IF;

			--Verifico la factura 
			IF (parametro->>'tipoCompr' = 'factura') THEN
				-- Si es una factura
				SELECT INTO rverif * 
				FROM facturaventa  
				WHERE nrodoc= parametro->>'pnrodoc' AND nrofactura  = parametro->>'nroCompr' AND nrosucursal = parametro->>'centro';
			END IF;

			--Verifico la orden 
			IF (parametro->>'tipoCompr' = 'orden') THEN
				-- Si es una orden
				SELECT INTO rverif * 
				FROM consumo 
				WHERE nrodoc = parametro->>'pnrodoc' and nroorden = parametro->>'nroCompr' AND centro = parametro->>'centro';
			END IF;

			--Verifico el legajo 
			IF (parametro->>'tipoCompr' = 'legajo') THEN
				-- Si es un legajo
				SELECT INTO rverif *
				FROM persona
					LEFT JOIN afilidoc ad USING (nrodoc, tipodoc)
					LEFT JOIN afilinodoc afnd USING (nrodoc, tipodoc)
					LEFT JOIN afiliauto aa USING (nrodoc, tipodoc)
					LEFT JOIN afilirecurprop arp USING (nrodoc, tipodoc)
					LEFT JOIN ca.persona cper ON (penrodoc = nrodoc)
					LEFT JOIN ca.empleado cemp ON (cemp.idpersona = cper.idpersona)
				WHERE nrodoc = parametro->>'pnrodoc' 
					AND (ad.legajosiu = parametro->>'nroCompr'
					OR afnd.legajosiu = parametro->>'nroCompr'
					OR aa.legajosiu = parametro->>'nroCompr'
					OR arp.legajosiu = parametro->>'nroCompr'
					OR cemp.emlegajo = parametro->>'nroCompr');
			END IF;

			--Confirmo las validaciones anteriores
			IF FOUND AND bverifica THEN
				IF ((rpersona.barra >= 30 AND rpersona.barra <= 99) OR (rpersona.barra >= 130 AND rpersona.barra <= 160)) THEN
					jsoncadena := concat('{ pnrodoc=', parametro->>'pnrodoc', '  , ptipodoc=', parametro->>'ptipodoc', ' , passMd5=', parametro->>'passMd5', ' , passTrip=', parametro->>'passTrip', ' , pemail=', parametro->>'pemail', ' , prolweb=', parametro->>'prolweb', ' , elusuario=', parametro->>'elusuario', '}');
					rrespuesta = w_crearusuarioweb(jsoncadena::character varying);
				ELSE
					RAISE EXCEPTION 'R-100, Los beneficiarios no pueden generar su usuario por este medio';
				END IF;
			ELSE
				RAISE EXCEPTION 'R-004: Alguno de los datos ingresados son incorrectos o el afiliado se encuentra en estado pasivo';
			END IF;  

		WHEN 'prestador' THEN 
			IF (nullvalue(parametro->>'cuit') OR nullvalue(parametro->>'elusuario')  
			OR nullvalue(parametro->>'passMd5') OR nullvalue(parametro->>'tipoCompr') OR nullvalue(parametro->>'nroCompr')) THEN
				RAISE EXCEPTION 'R-003, Parámetros inválidos, revíselos y envíelos nuevamente. Parámetros: %',parametro;
			END IF;

			 -- Verifico que tenga usuario
			SELECT INTO rusuarioweb * FROM prestador 
				NATURAL JOIN w_usuarioprestador
				NATURAL JOIN w_usuarioweb
			WHERE pcuit = parametro->>'cuit'
				AND NOT nullvalue(idusuarioweb);

			-- Verifico el orden de pago
			IF (parametro->>'tipoCompr' = 'ordPago') THEN
				SELECT INTO rverif idordenpagocontable, idcentroordenpagocontable
					FROM prestador
					NATURAL JOIN ordenpagocontable
					LEFT JOIN w_usuarioprestador USING (idprestador)
				WHERE  pcuit = parametro->>'cuit'
					AND idordenpagocontable = parametro->>'nroCompr';
			END IF;

			IF (NOT nullvalue(rverif.idordenpagocontable) AND NOT nullvalue(rverif.idcentroordenpagocontable) AND nullvalue(rusuarioweb)) THEN
				rrespuesta = w_crearusuarioweb(parametro::character varying);
			ELSE
				RAISE EXCEPTION 'R-005: Alguno de los datos ingresados son incorrectos';
			END IF;

		ELSE
	END CASE;
	
	respuestajson = json_build_object('barra', rrespuesta);

return respuestajson;

end;
 
$function$
