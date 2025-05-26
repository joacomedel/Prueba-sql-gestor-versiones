CREATE OR REPLACE FUNCTION public.resetearclavetarjeta(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	 latarjeta RECORD;
	 resp boolean;
	 elnrodoc integer;
     eltipodoc integer;
  




BEGIN
     elnrodoc =$1;
     eltipodoc =$2;
     
     resp = true;
     
     -- Busco la tarjeta del afiliado que se encuentra en circulacion (que no fue dada de baja idestadotipo <> 4; )
     SELECT into latarjeta *
     FROM  tarjeta
     NATURAL JOIN  tarjetaestado   
     --NATURAL JOIN  tarjetalogin  
     WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and nullvalue(tefechafin) and idestadotipo =3;

--     1    solicitado
--     2    CONFECCIONADO
--     3    ENTREGADO
--     4    De BAJA
    
      IF FOUND THEN

               delete  FROM  tarjetalogin  
               WHERE idtarjeta=latarjeta.idtarjeta and idcentrotarjeta=latarjeta.idcentrotarjeta;
               
               INSERT INTO tarjetalogin (tlbloqueada, idtarjeta ,idcentrotarjeta,
                 tlcodigo , tlcambiarpass )
                 (
                   SELECT false ,  idtarjeta,idcentrotarjeta, md5 (substr(nrodoc, 0, 5) ),true
                   FROM tarjeta
                   NATURAL JOIN tarjetaestado
                   WHERE    nrodoc=elnrodoc and tipodoc=eltipodoc   and  idestadotipo = 3 and nullvalue(tefechafin)
                 );

             resp = true;
           
            
     ELSE resp = false;

     
    END IF;





RETURN resp;
END;
$function$
