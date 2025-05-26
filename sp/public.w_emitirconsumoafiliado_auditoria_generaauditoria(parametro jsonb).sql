CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_auditoria_generaauditoria(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*
* {"codigo":"b46b5058878a1d34380f691fdd4103f1","info_sistema_solicita":"suap", "uwnombre":"usudesa" }
*/
DECLARE
--VARIABLES 
   --vvalorcagamercadopago INTEGER;
--RECORD
      respuestajson jsonb;
      rexiste RECORD;
      rorden  RECORD;
      rformulario RECORD;
	  pfiltros VARCHAR;
    
	 vnroorden bigint;
	 vcentro bigint;
     
begin
    IF nullvalue(parametro->>'codigo') OR LENGTH(parametro->>'codigo') < 3 THEN
		      RAISE EXCEPTION 'R-006, Se requeire el parametro adecuado (tokensession,%)',parametro->>'tokensession';
	ELSE 
		SELECT INTO rexiste * FROM w_usuariowebtokensession WHERE uwtkscodigo = trim(parametro->>'codigo');
	    IF FOUND THEN
			IF nullvalue(rexiste.uwtksfechauso) OR not nullvalue(parametro->>'camino') THEN 
					vnroorden = (rexiste.uwtkscodigo)::bigint / 100;
	   				vcentro = (rexiste.uwtkscodigo)::bigint  % 100;
			   		SELECT INTO rorden * FROM consumo NATURAL JOIN persona
									NATURAL JOIN ordenrecibo 
									WHERE nroorden = vnroorden AND centro = vcentro;
	   				IF FOUND THEN
                                             pfiltros = concat('{ nroformulario=',rexiste.uwtkscodigo,'');
                                             IF not nullvalue(parametro->>'camino') THEN 
                                                pfiltros = concat(pfiltros,' ,camino=',parametro->>'camino','');
                                             END IF;
                                             IF not nullvalue(parametro->>'nombre') THEN 
                                                pfiltros = concat(pfiltros,' ,nombre=',parametro->>'nombre','');
                                             END IF;

                                         pfiltros = concat(pfiltros,'}');
	            		 PERFORM auditoriamedica_conformulario_solicitarauditoria(pfiltros); 
        				
       				ELSE
      					RAISE EXCEPTION 'R-008, El Token asociado a esa Orden No existe (parametros,%)',rexiste.*;
       				END IF;
				ELSE 
					RAISE EXCEPTION 'R-010, El Token asociado a esa Orden ya se uso (codigo,%,venm%)',rexiste.uwtkscodigo,rexiste.uwtksfechauso;
				END IF;
	
		ELSE 
				RAISE EXCEPTION 'R-007, El Token asociado a esa Orden No existe (tokensession,%)',parametro->>'tokensession';
		END IF;
	END IF;
	

       return parametro;

end;
$function$
