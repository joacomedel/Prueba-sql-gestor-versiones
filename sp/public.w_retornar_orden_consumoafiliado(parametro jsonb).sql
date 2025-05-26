CREATE OR REPLACE FUNCTION public.w_retornar_orden_consumoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"codigo":"nroordencentro","info_sistema_solicita":"suap"}

*/
DECLARE
       respuestajson jsonb;
       jsonafiliado jsonb;
       jsonaprestador jsonb;
       jsonformulario jsonb;
       param jsonb;
       
       rorden RECORD;
       rverifica RECORD;
       rrecibocompleto RECORD;
       rformulariocompleto RECORD;
       rrecibo RECORD;
       	
--VARIABLES
       vnroorden BIGINT;
       vcentro integer;
      
begin

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


                           IF rorden.anulado THEN 
                                 --La orden esta anulada, no puede ser facturada
                                 RAISE EXCEPTION 'R-022, La orden Solicitada se encuentra anulada.(nroorden,centro,%)',parametro;
                           ELSE 
                                IF (not nullvalue(parametro->>'info_sistema_solicita') 
                                     AND   parametro->>'info_sistema_solicita' <> 'Siges') OR nullvalue(parametro->>'info_sistema_solicita')  THEN 
                                 --MaLaPi 27-12-2022 Si el WS lo usa Siges, no me importa si ya fue facturada, espara mostrar el formulario de diabtes
                                 SELECT INTO rverifica * FROM ordenesutilizadas WHERE nroorden = vnroorden AND centro = vcentro;
                                 IF FOUND THEN 
                                 --La orden esta anulada, no puede ser facturada
                                     RAISE EXCEPTION 'R-023, La orden Solicitada se encuentra ya se encunentra Facturada.(nroorden,centro,%)',parametro;
                                 END IF; 
                                 END IF;

			param = concat('{"NroAfiliado":"',rorden.nrodoc,'","Barra":',rorden.barra,',"NroDocumento":null,"TipoDocumento":null,"Track":null,"info_solicita":"sosunc"} ');
			--12-01-2022 MaLaPi Dejo de verificar el estado del afiliado actualmente, pues solo sirve el estado que tenia al emitir la orden valorizada
                        --SELECT INTO jsonafiliado * FROM w_determinarelegibilidadafiliado(param);
                        
                         select into jsonafiliado row_to_json(t)
                         from (
                               select nrodoc as nroafiliado
				     ,barra
				     ,nrodoc as nrodocumento
				     ,descrip as tipodocumento
				     ,nombres
				     ,apellido
				     ,sexo
                                     ,tipodoc as idtipodocumento
				     ,fechanac as fechanacimiento
                                     ,TO_CHAR(fechafinos, 'dd/mm/yyyy') as fechafinos
                                     ,CASE WHEN fechafinos > current_date THEN 'Activo' ELSE 'Pasivo' END as estado
                                     ,concat(nrodoc,'-',barra) as nroafiliado 
                                     ,extract('years' from age(current_date,fechanac)) as edad,concat(carct,'',telefono) as telefonos,email
				      ,(
                                        select  array_to_json(array_agg(row_to_json(t)))
                                        from ( 
	                                    select idplancoberturas,nombreimprimir 
                                           from plancobertura 
                                           natural join plancobpersona 
                                        where nrodoc = rorden.nrodoc 
                                              and (nullvalue(pcpfechafin) OR pcpfechafin > current_date)
                                             ) as t
                                     ) as  planesafiliado
                                    FROM  persona NATURAL JOIN tiposdoc 
                                    WHERE nrodoc  = rorden.nrodoc
                             ) as t;

                         select into jsonaprestador row_to_json(t)
                         from (
                          SELECT pcuit as prespcuit,pdescripcion as prespdescripcion,case when nullvalue(pemail) THEN '' ELSE pemail END as prespemail
                               ,case when nullvalue(pcontacto) THEN '' ELSE pcontacto END as prespcontacto
                               ,case when nullvalue(ptelefonomovil) THEN '' ELSE ptelefonomovil END as presptelefonomovil
                               ,matricula.nromatricula as presmatricula,matricula.malcance as presmalcance ,matricula.mespecialidad as presmespecialidad	 
                          FROM ordvalorizada
                          LEFT JOIN prestador ON nromatricula = idprestador
                          LEFT JOIN matricula USING(idprestador)
                         WHERE nroorden = vnroorden AND centro = vcentro
                        ) as t;

			SELECT INTO rrecibocompleto idrecibo,centro FROM recibo WHERE idrecibo = rorden.idrecibo AND centro = rorden.centro; 
			respuestajson = row_to_json(rrecibocompleto);
			SELECT INTO respuestajson w_ordenrecibo_informacion_json(respuestajson);

                        
                         SELECT INTO rformulariocompleto fmifformulario FROM fichamedicainfoformulario 
                                                            WHERE nullvalue(fmiffechafin) AND fmifnroorden = vnroorden 
                                                            AND	fmifcentro = vcentro;
                         IF FOUND THEN 
                             jsonformulario = row_to_json(rformulariocompleto);
                             --jsonformulario = remove_key(jsonformulario,'tokensession'); 
                             SELECT INTO respuestajson replace(  (jsonafiliado::text || respuestajson::text || jsonaprestador::text || jsonformulario::text) ,'}{',', ')::jsonb; 
                         ELSE
                             SELECT INTO respuestajson replace(  (jsonafiliado::text || respuestajson::text || jsonaprestador::text ) ,'}{',', ')::jsonb; 
                         END IF;
                        
			
                        --SELECT INTO respuestajson replace(  (jsonafiliado::text || respuestajson::text ) ,'}{',', ')::jsonb; 
                      END IF; 
                   END IF;
		END IF;

		
	

      return respuestajson;

end;$function$
