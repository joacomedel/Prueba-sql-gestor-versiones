CREATE OR REPLACE FUNCTION public.expendio_asentarrecetariotprecibo()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
rrecetariotp RECORD;

--VARIABLES
resp bigint;
resp1 boolean;
nrortp INTEGER;

BEGIN
    resp = 0;
    resp1 = false;
    SELECT INTO rrecetariotp * FROM temporden;
/*expendo tantos recetarios como el afiliado quiera*/  
    FOR nrortp IN 1..rrecetariotp.cantordenes LOOP 

          SELECT * INTO  resp1 FROM expendio_generarrecetariotratamientoprolongado();
         
    END LOOP;
  
    IF (resp1) THEN
       SELECT * INTO  resp FROM expendio_asentarreciboorden();
    END IF;
    return resp;	
END;
$function$
