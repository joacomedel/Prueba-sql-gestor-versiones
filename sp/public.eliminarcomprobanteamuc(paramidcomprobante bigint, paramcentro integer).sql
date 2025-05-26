CREATE OR REPLACE FUNCTION public.eliminarcomprobanteamuc(paramidcomprobante bigint, paramcentro integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   cursorimportes CURSOR FOR  select * from importesrecibo where idrecibo=$1 and centro=$2;
    suma real;
  reciboimporte RECORD;
  recibouso RECORD;
BEGIN
       suma=0;
      
       OPEN cursorimportes;
    FETCH cursorimportes into reciboimporte;
    WHILE found LOOP
                 if (reciboimporte.idformapagotipos=1 or reciboimporte.idformapagotipos=6) then
             suma= reciboimporte.importe + suma;
                 end if;

    fetch cursorimportes into reciboimporte;
    END LOOP;
       close cursorimportes;

     update importesrecibo set importe=round(CAST (suma AS numeric),2) where idrecibo=$1 and idformapagotipos=6 and centro=$2;

     delete from importesrecibo where idrecibo=$1 and idformapagotipos=1 and centro=$2;

      select into recibouso * from ordenrecibo natural join orden where idrecibo=$1 and centro=$2;

   -- select * from importesorden where nroorden=recibouso.nroorden

    update importesorden set importe=round(CAST (suma AS numeric),2) where nroorden=recibouso.nroorden and idformapagotipos=6 and centro=$2;

    delete   from importesorden where nroorden=recibouso.nroorden and idformapagotipos=1 and centro=$2;

return 'true';

END;$function$
