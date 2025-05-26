CREATE OR REPLACE FUNCTION public.asentarconsultarecibo()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE

resp bigint;
resp1 boolean;
rrecibo record;

BEGIN
    resp = 0;
    resp1 = false;
    select * into resp1
           from asentarconsulta();
    if (resp1) then
       select * into resp
              from asentarreciboorden();
    end if;
    
   
    return resp;	
END;
$function$
