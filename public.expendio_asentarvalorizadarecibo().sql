CREATE OR REPLACE FUNCTION public.expendio_asentarvalorizadarecibo()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE

/*
Estructura ttvalorizada
mespecialidad ,malcance ,nromatricula ,ordenreemitida , centroreemitida 

 -- temporden;
 -- tempitems;
*/
dato record;
resp bigint;
resp1 boolean;
bandera bigint;

BEGIN
    resp = 0;
    resp1 = false;
    SELECT INTO dato * FROM temporden;
    bandera = dato.ordenreemitida;

    if (bandera<>0) then
            select * into resp1 from reemitirorden();
    else

            select * into resp1 from expendio_asentarvalorizada();
            if (resp1) then
                       select * into resp  from expendio_asentarreciboorden();
            end if;

    end if;

    return resp;	
END;
$function$
