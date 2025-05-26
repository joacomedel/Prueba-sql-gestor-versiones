CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_auditoria_guardar(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/*
*{"tokensession":"3606c369430142ef288b8cb4c8d1a373","apellido":"LUCERO","nombres":"JORGE HIPOLITO","nrodocumento":"06819116"
,"nroafiliado":"06819116-35","email":"yolandaschamber@yahoo.com.ar","telefonos":"dasdsads"
,"edad":"74","sexo":"M","peso":"","talla":"","imc":"","dosishipo":"","dosisincretina":"","monitoreodia":""
,"monitoreosemana":"","nomprofesional":"","matprovincial":"","matnacional":"","provincia":"","Email":"","telefono":"","firma":""}
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
--row_to_json(row(1,'foo'))
	   vttl =  CURRENT_TIMESTAMP + (30 * interval '1 minute');
       IF nullvalue(parametro->>'tokensession') OR LENGTH(parametro->>'tokensession') < 3 THEN
		      RAISE EXCEPTION 'R-006, Se requeire el parametro adecuado (codigo,%)',parametro->>'codigo';
	    ELSE 
		SELECT INTO rexiste * FROM w_usuariowebtokensession WHERE uwtkstoken = trim(parametro->>'tokensession');
	    IF FOUND THEN
			IF nullvalue(rexiste.uwtksfechauso) THEN 
				IF (rexiste.uwtksttl > now()) THEN 
					vnroorden = (rexiste.uwtkscodigo)::bigint / 100;
	   				vcentro = (rexiste.uwtkscodigo)::bigint  % 100;
			   		SELECT INTO rorden * FROM consumo NATURAL JOIN persona
									NATURAL JOIN ordenrecibo 
									WHERE nroorden = vnroorden AND centro = vcentro;
	   				IF FOUND THEN
						SELECT INTO usuariojson sys_dar_usuario_web(parametro);
						--UPDATE w_usuariowebtokensession SET uwtksfechauso = now() WHERE uwtkstoken = trim(parametro->>'tokensession');
					   --Aqui debo guardar los datos
					   PERFORM w_emitirconsumoafiliado_auditoria_guardarinfo(parametro);
	            		
       				ELSE
      					RAISE EXCEPTION 'R-008, El Token asociado a esa Orden No existe (parametros,%)',rexiste.*;
       				END IF;
				ELSE 
					RAISE EXCEPTION 'R-008, El Token asociado a esa Orden ya se vencio (codigo,%,venm%)',parametro->>'codigo',rexiste.uwtksttl;
				END IF;
				ELSE 
					RAISE EXCEPTION 'R-010, El Token asociado a esa Orden ya se uso (codigo,%,venm%)',rexiste.uwtkscodigo,rexiste.uwtksfechauso;
				END IF;
	
	
	
		ELSE 
				RAISE EXCEPTION 'R-007, El Token asociado a esa Orden No existe (tokensession,%)',parametro->>'tokensession';
		END IF;
	END IF;
       return respuestajson;

end;
$function$
