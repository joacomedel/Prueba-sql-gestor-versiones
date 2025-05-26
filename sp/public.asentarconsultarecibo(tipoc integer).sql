CREATE OR REPLACE FUNCTION public.asentarconsultarecibo(tipoc integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE

resp bigint;
resp1 boolean;

BEGIN
    resp = 0;
    resp1 = false;
    select * into resp1
           from asentarconsulta(tipoc);
    if (resp1) then
       select * into resp
              from asentarreciboorden();
    end if;
    return resp;	
END;
$function$
