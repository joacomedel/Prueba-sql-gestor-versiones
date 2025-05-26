CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_auditoria_getinfo(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*
* {"tokensession":"b46b5058878a1d34380f691fdd4103f1","info_sistema_solicita":"suap", "uwnombre":"usudesa" }
*/
DECLARE
--VARIABLES 
   --vvalorcagamercadopago INTEGER;
--RECORD
      respuestajson jsonb;
      rexiste RECORD;
      rorden  RECORD;
      rformulario RECORD;
     -- rpagocupon RECORD;
      --vimporte float;
     --vnrotarjeta VARCHAR;
	 vnroorden bigint;
	 vcentro bigint;
     -- vnrocupon VARCHAR;
begin
    IF nullvalue(parametro->>'tokensession') OR LENGTH(parametro->>'tokensession') < 3 THEN
		      RAISE EXCEPTION 'R-006, Se requeire el parametro adecuado (tokensession,%)',parametro->>'tokensession';
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
					
	            		SELECT INTO respuestajson *  
								FROM w_retornar_orden_consumoafiliado(concat('{','"codigo":', rexiste.uwtkscodigo ,', "info_sistema_solicita":"Siges"}')::jsonb);
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
