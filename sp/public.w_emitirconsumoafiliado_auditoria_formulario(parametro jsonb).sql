CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_auditoria_formulario(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"centro": 1, "idrecibo": 748447, "nroorden": 1014722 }
* {"codigo":"1090235001","info_sistema_solicita":"suap", "uwnombre":"usudesa" }
*/
DECLARE

      respuestajson jsonb;
	  usuariojson jsonb;
      rorden RECORD;
      rexiste  RECORD;
      rformulario RECORD;
      vnroorden bigint;
	 vcentro bigint;
	 vttl timestamp;
begin

	   vttl =  CURRENT_TIMESTAMP + (30 * interval '1 minute');
       IF nullvalue(parametro->>'codigo') OR LENGTH(parametro->>'codigo') < 3 THEN
		      RAISE EXCEPTION 'R-006, Se requeire el parametro adecuado (codigo,%)',parametro->>'codigo';
	    ELSE 
	   vnroorden = (parametro->>'codigo')::bigint / 100;
	   vcentro = (parametro->>'codigo')::bigint  % 100;

	   SELECT INTO rorden * FROM consumo 
	                        NATURAL JOIN persona
				NATURAL JOIN ordenrecibo 
				WHERE nroorden = vnroorden AND centro = vcentro;
	   IF FOUND THEN
	            SELECT INTO rexiste * FROM w_usuariowebtokensession WHERE uwtkscodigo = parametro->>'codigo';
				IF FOUND THEN
					IF rexiste.uwtksttl > now() THEN 
						SELECT INTO rformulario 'https://www.sosunc.org.ar/sigesweb/vista/w_externo/form.php' as url
	   					,md5(parametro->>'codigo') as tokensession,parametro->>'ttl_session' as ttl_session;
	   					respuestajson = row_to_json(rformulario);

                                                 IF parametro->>'info_sistema_solicita' = 'Siges' THEN 
                                                    --MaLAPi 01-09-2022 Si es Siges, no importa que este vencido se usa igual, prorrogo el vto
                                                      UPDATE w_usuariowebtokensession SET uwtksfechauso = null,ttl_session = parametro->>'ttl_session' ,uwtksmodifico= now(),uwtksttl = vttl , uwtkstoken = md5(parametro->>'codigo') 
                                                                                 WHERE uwtkscodigo = parametro->>'codigo' ;
                                                 END IF; 

                                                     


					ELSE 
						IF parametro->>'info_sistema_solicita' = 'Siges' THEN 
                                                    --MaLAPi 01-09-2022 Si es Siges, no importa que este vencido se usa igual, prorrogo el vto
                                                      UPDATE w_usuariowebtokensession SET uwtksfechauso = null,ttl_session = parametro->>'ttl_session', uwtksmodifico= now(),uwtksttl = vttl , uwtkstoken = md5(parametro->>'codigo') 
                                                                                 WHERE uwtkscodigo = parametro->>'codigo';
                                                      SELECT INTO rformulario 'https://www.sosunc.org.ar/sigesweb/vista/w_externo/form.php' as url
	   					       ,md5(parametro->>'codigo')  as tokensession,parametro->>'ttl_session' as ttl_session;
	   					        respuestajson = row_to_json(rformulario);
                                                ELSE

                                                      RAISE EXCEPTION 'R-008, El Token asociado a esa Orden ya se vencio (codigo,%,venm%)',parametro->>'codigo',rexiste.uwtksttl;
                                                END IF;
					END IF;
				ELSE 
				    SELECT INTO usuariojson sys_dar_usuario_web(parametro);
					INSERT INTO w_usuariowebtokensession(idusuarioweb,uwtkscodigo, uwtksquien,uwtksttl,nroorden,centro,uwtkstoken,ttl_session) 
					VALUES((usuariojson->>'idusuarioweb')::bigint,parametro->>'codigo',parametro->>'info_sistema_solicita',vttl,vnroorden,vcentro,md5(parametro->>'codigo'),parametro->>'ttl_session');
					SELECT INTO rformulario 'https://www.sosunc.org.ar/sigesweb/vista/w_externo/form.php' as url
	   					,md5(parametro->>'codigo')  as tokensession,parametro->>'ttl_session'  as ttl_session;
	   					respuestajson = row_to_json(rformulario);
				END IF;
--'https://www.sosunc.org.ar/sigesweb/vista/w_externo/form.php'
       ELSE
      		RAISE EXCEPTION 'R-009, El No existe la orden solicitada (codigo,%)',parametro->>'codigo';
       END IF;
	END IF;
       return respuestajson;

end;
$function$
