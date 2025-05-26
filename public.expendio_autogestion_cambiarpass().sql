CREATE OR REPLACE FUNCTION public.expendio_autogestion_cambiarpass()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

  resp boolean;
  rdatoseag RECORD;
  datotarjeta RECORD;
BEGIN

resp = false;

SELECT INTO rdatoseag * FROM temp_expendioag;
 

IF (rdatoseag.accion ILIKE '%cambiarpass%') THEN
        
-- busco la tarjeta activa para la persona
     SELECT into datotarjeta *
     FROM  tarjeta
     NATURAL JOIN tarjetaestado
     WHERE tipodoc = rdatoseag.tipodoc and  nrodoc=rdatoseag.nrodoc -- q se corresponda con la persona
           and nullvalue(tefechafin) and idestadotipo = 3 -- que la tarjeta este activa
          
     ;	
    -- Si tiene una tarjeta activa la retorno para posterior verificacion
     IF  found THEN  
	  UPDATE tarjetalogin SET tlcambiarpass = false, tlcodigo = md5(rdatoseag.codigo)
          WHERE idcentrotarjeta =  datotarjeta.idcentrotarjeta AND idtarjeta = datotarjeta.idtarjeta;
	  resp = true;
     END IF;


   
END IF;


return resp;
     



 
END;
$function$
