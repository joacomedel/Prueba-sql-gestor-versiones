CREATE OR REPLACE FUNCTION public.w_prestador_agregar_informacion(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"iddeuda":"08216252","idcentrodeuda":"1","importepago":"1.0","autorizacion":"0","nrotarjeta":"0","nrocupon":"0"}
*/
DECLARE
--VARIABLES 
  
--RECORD
      respuestajson jsonb;
      respuestajson_info jsonb;  
      respuestajson_msn jsonb;
      respuestajson_domi jsonb;
      respuestajson_contacto jsonb;
      rprestador RECORD;
      rprestador_info  RECORD;
      rformapagouw RECORD;
      vidprestador bigint;
      
begin
       
       IF nullvalue(parametro->>'idprestador') OR nullvalue(parametro->>'prestador_accion') THEN 
		RAISE EXCEPTION 'R-001, Todos los parametros deben estar completos.  %',parametro;
       END IF;
       vidprestador = trim(parametro->>'idprestador')::bigint;
	IF parametro->>'prestador_accion' ilike '%fiscal' THEN
         
          UPDATE w_prestador_fiscal SET pffechafin = now() WHERE idprestador = trim(parametro->>'idprestador')::bigint AND nullvalue(pffechafin);

         -- INSERT INTO w_prestador_fiscal(idprestador,pfrazonsocial,pfcuit,pfcconscuitidarchivo,pfexafipidarchivo,pfexrentaidarchivo,pfesagrupador)
         -- VALUES(trim(parametro->>'idprestador')::bigint,parametro->>'pfrazonsocial',parametro->>'pfcuit',parametro->>'pfcconscuitidarchivo',parametro->>'pfexafipidarchivo',parametro->>'pfexrentaidarchivo',parametro->>'pfesagrupador'); 
INSERT INTO w_prestador_fiscal(idprestador,pfrazonsocial,pfdescripcion,pfcuit,pfesagrupador)
          VALUES(vidprestador,parametro->>'pfrazonsocial',parametro->>'pfdescripcion',parametro->>'pfcuit',parametro->>'pfesagrupador'='true'); 

        END IF;

        IF parametro->>'prestador_accion' ilike '%dom_legal' OR parametro->>'prestador_accion' ilike '%dom_real' THEN

            UPDATE w_prestador_domi SET pdfechafin = now() WHERE idprestador = parametro->>'idprestador' AND nullvalue(pdfechafin) AND pdtipo ilike parametro->>'prestador_accion';
            INSERT INTO w_prestador_domi(idprestador,pdcalle,pdnumero,pdotro,pdidlocalidad,pdidprovincia,pdtipo) 
             VALUES(vidprestador,parametro->>'pdcalle',parametro->>'pdnumero',parametro->>'pdotro',parametro->>'pdidlocalidad',parametro->>'pdidprovincia',parametro->>'prestador_accion'); 


        END IF;

        IF parametro->>'prestador_accion' = 'contacto_adm' OR parametro->>'prestador_accion' = 'contacto_fac'
           OR parametro->>'prestador_accion' = 'contacto_convenio' OR parametro->>'prestador_accion' = 'contacto_auditoria'
           OR parametro->>'prestador_accion' = 'contacto_info'  THEN

            UPDATE w_prestador_contacto SET pcfechafin = now() WHERE idprestador = parametro->>'idprestador' AND nullvalue(pcfechafin) AND pctipo ilike parametro->>'prestador_accion';
            INSERT INTO w_prestador_contacto(idprestador,pcdescripcion,pccorreo,pccelular,pctelefono,pctipo) 
             VALUES(vidprestador,parametro->>'pcdescripcion',parametro->>'pccorreo',parametro->>'pccelular',parametro->>'pctelefono',parametro->>'prestador_accion'); 


        END IF;

 
       return respuestajson;

end;
$function$
