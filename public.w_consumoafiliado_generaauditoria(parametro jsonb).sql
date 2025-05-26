CREATE OR REPLACE FUNCTION public.w_consumoafiliado_generaauditoria(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$ 
DECLARE
--RECORD 
  ritems RECORD;
  rfichamedica RECORD;
  rpendienteauditoria RECORD;
--JSONB
  respuestajson jsonb;
       
	
BEGIN

 IF existecolumtemp('tempitems', 'auditoria') THEN 
    SELECT INTO ritems * FROM tempitems WHERE auditoria; 
--La orden tiene practicas que requieren auditoria, entonces genero el turno
    IF FOUND THEN 
       SELECT INTO rfichamedica * FROM alta_modifica_auditoria_medica_turno(concat('nrodoc=',parametro->>'nrodoc' ,',', 'tipodoc=',parametro->>'tipodoc',',', 'comentario= Desde SP w_consumoafiliado_generaauditoria' ,','
,'nroorden =', parametro->>'nroorden' ,',', 'centro =', parametro->>'centro'));
    END IF; 
 END IF; 

      
 return parametro;

END;

$function$
