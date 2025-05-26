CREATE OR REPLACE FUNCTION public.w_abmctactecliente(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
select from w_abmctactecliente('{"NroDocumento":"34812699","operacion":"alta"}'::jsonb);
*/

DECLARE
       respuestajson jsonb;
      
--RECORD
       rcliente RECORD;
       rrespuesta RECORD;
begin 

 IF nullvalue(parametro->>'NroDocumento') OR nullvalue(parametro->>'operacion') THEN 
     RAISE EXCEPTION 'R-001, Los parámetros deben estar completos.  %',parametro;       
 
 ELSE 
  --Busco los datos del cliente 
    SELECT INTO rcliente * FROM cliente WHERE nrocliente = parametro->>'NroDocumento';
    IF NOT FOUND THEN
	RAISE EXCEPTION 'A-001, El afiliado no es un cliente de la obra social.(NroDocumento,%)',parametro->>'NroDocumento';
    ELSE 
	
        SELECT INTO rrespuesta sys_abmctactecliente(concat('{nrocliente=' ,parametro->>'NroDocumento', ',barra =',rcliente.barra,' , cccdtohaberes= ','true',
' , idformapagoctacte= ',1,' , idestadotipo= ',case when (parametro->>'operacion')  ilike '%alta%' THEN 8 when (parametro->>'operacion') ilike '%baja%' then 9 END,' }')) as respuesta,'lala' as otro;  
       
        respuestajson = row_to_json(rrespuesta);
    END IF;


 END IF;
	 
    	
 return respuestajson;

end;
 $function$
