CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_auditoria(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
select from w_emitirconsumoafiliado_auditoria('{"idcapitulo":"42","idnomenclador":"12","idsubcapitulo":"01","idpractica":"01","idasocconv":89,"idtempitem":1,"cantidadpracticas":3,"idplancoberturas":1}'::jsonb);
*/
DECLARE
--RECORD 
  rseconsume RECORD;
  rfichamedica RECORD;

--JSONB
  respuestajson jsonb;
       
    
BEGIN
        SELECT INTO rseconsume * FROM practicavalores
    WHERE  idcapitulo =  parametro->>'idcapitulo' AND idsubespecialidad = parametro->>'idnomenclador' AND idsubcapitulo = parametro->>'idsubcapitulo' AND idpractica = parametro->>'idpractica' AND not internacion AND 
    idasocconv  = parametro->>'idasocconv';

    --    RAISE NOTICE '(rseconsume,%)',rseconsume;
         RAISE NOTICE 'auditoria (parametro,%)',parametro;

    INSERT INTO tempitems (idtemitems,cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancob,auditada,porcentaje,porcentajesugerido,idpiezadental,idzonadental,idletradental,amuc,iicoberturaamuc,afiliado,sosunc,tierror,auditoria)      
VALUES(  
        (parametro->>'idtempitem')::integer
        ,(parametro->>'cantidadpracticas')::integer
    ,rseconsume.importe
    ,parametro->>'idnomenclador'
    ,parametro->>'idcapitulo'
    ,parametro->>'idsubcapitulo'
    ,parametro->>'idpractica'
    ,parametro->>'idplancoberturas'
    ,null
    ,0
        ,(parametro->>'porcentajesugerido')::integer
    ,''
    ,''
    ,''
    ,0,(parametro->>'coberturaamuc')::double precision,0,0      --- BelenA - VAS 060525 se agrega iicoberturaamuc y coberturaamuc para que tenga la cobertura AMUC
       ,CASE WHEN parametro->>'auditoria' ilike '%cantidad%' THEN 'No quedan practicas para ser consumidas. Requiere autorizacion.' ELSE 'La practica requiere autorizacion.' END
       ,true  );
                    
  --KR 01-07-19 Se genera el pendiente de auditoria 
  --   SELECT INTO rfichamedica * FROM alta_modifica_auditoria_medica_turno(concat('nrodoc=',parametro->>'nrodoc' ,',', 'tipodoc=',parametro->>'tipodoc',',', 'comentario= Desde SP w_emitirconsumoafiliado_auditoria. ' ));

  return respuestajson;

END;

$function$
