CREATE OR REPLACE FUNCTION public.expendio_asentarconsultarecibo()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE

/*
Estructura ttvalorizada
mespecialidad ,malcance ,nromatricula ,ordenreemitida , centroreemitida 

 -- temporden;
 -- tempitems;
*/
--RECORD
dato RECORD;
rordenconsulta RECORD;
--rdatoseag RECORD;seconsume RECORD;
--CURSOR
cordenconsulta refcursor;

--VARIABLES
resp bigint;
resp1 boolean;
bandera bigint;
nroordenes INTEGER;


BEGIN
    resp = 0;
    resp1 = false;
   
    SELECT INTO rordenconsulta * FROM temporden; 
    RAISE NOTICE 'expendio_asentarconsultarecibo (%) ',rordenconsulta;
    IF rordenconsulta.tipo = 4 THEN 
        --MaLaPi 24-02-2023 Cuando se trata de una orden de consulta por el expendio 2.0 esta en el item la cantidad de practicas... las traslado a la cabecera
       UPDATE temporden SET cantordenes = t.cantidad FROM ( SELECT sum(cantidad) as cantidad FROM tempitems ) as t;
       SELECT INTO rordenconsulta * FROM temporden; 
       UPDATE tempitems SET cantidad = 1, importe = importe / rordenconsulta.cantordenes,amuc = amuc / rordenconsulta.cantordenes ,afiliado = afiliado / rordenconsulta.cantordenes ,sosunc = sosunc/ rordenconsulta.cantordenes ;
      SELECT * INTO  resp1 FROM expendio_asentarvalorizada();
     ELSE
        /*expendo tantas ordenes como las que el afiliado quiera*/
    FOR nroordenes IN 1..rordenconsulta.cantordenes LOOP 

          SELECT * INTO  resp1 FROM expendio_asentarvalorizada();
         
    END LOOP;

    END IF;
       RAISE NOTICE 'expendio_asentarconsultarecibo (%) ',rordenconsulta;



/*genero el recibo por las ordenes expendidas*/
    if (resp1) then
               select * into resp  from expendio_asentarreciboorden();
    
    end if;
   return resp;	
END;
$function$
