CREATE OR REPLACE FUNCTION public.asentarvalorizadarecibo(tipoc integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
valorizada CURSOR FOR
              SELECT *
              FROM ttvalorizada;
/*
malcance           varchar
nromatricula       integer
mespecialidad      varchar
ordenreemitida     bigint
centroreemitida    ingeger
*/
dato record;
resp bigint;
resp1 boolean;
bandera bigint;

BEGIN
    resp = 0;
    resp1 = false;
    open valorizada;
    fetch valorizada into dato;
    bandera = dato.ordenreemitida;
    close valorizada;

    if (bandera<>0) then
       select * into resp1
              from reemitirorden();
    else


       select * into resp1
           from asentarvalorizada(tipoc);

       if (resp1) then
          select * into resp
              from asentarreciboorden();
       end if;

    end if;

    return resp;	
END;
$function$
