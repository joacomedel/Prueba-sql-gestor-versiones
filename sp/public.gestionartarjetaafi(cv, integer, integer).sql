CREATE OR REPLACE FUNCTION public.gestionartarjetaafi(character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	 latarjeta RECORD;
      -- Busco la tarjeta del afiliado que se encuentra en circulacion (que no fue dada de baja idestadotipo <> 4; )
    tarjetas CURSOR FOR SELECT *    FROM  tarjeta     NATURAL JOIN  tarjetaestado
                 WHERE nrodoc=$1 and tipodoc=$2 and nullvalue(tefechafin) and idestadotipo <> 4;

	 elcupon  RECORD;
	 resp boolean;
	 elnrodoc character varying;
     eltipodoc integer;
     elidestadotipo integer;

BEGIN
     elnrodoc =$1;
     eltipodoc =$2;
     elidestadotipo= $3;
     
     
open tarjetas;
fetch tarjetas into latarjeta;
     ----     1   solicitado
     ----     2    CONFECCIONADO
     ----     3    ENTREGADO
     ----     4    De BAJA

    IF (elidestadotipo = 1 )THEN
      SELECT INTO resp creartarjeta(elnrodoc, eltipodoc);
    END IF;
 
     
    IF (elidestadotipo = 2 or  elidestadotipo = 3 or elidestadotipo = 4) THEN    
    --si hay mas de una tarjeta para la persona, a la primera q encuentro la cambio de estado y al resto le doy de baja
       SELECT INTO resp cambiarestadotarjeta(latarjeta.idtarjeta , latarjeta.idcentrotarjeta,elidestadotipo);
       
         
              -- Si se entrega la tarjeta tambien entrego el cupon vinculado a la tarjeta
           
              IF (  elidestadotipo = 2 or elidestadotipo = 3) THEN
                 SELECT INTO elcupon *
                 FROM cupon
                 WHERE idcentrotarjeta =latarjeta.idcentrotarjeta and idtarjeta =latarjeta.idtarjeta;
                 SELECT INTO resp cambiarestadocupon( elcupon.idcupon,elcupon.idcentrocupon ,elidestadotipo);
              END IF;
	
    
       fetch tarjetas into latarjeta;
       --si hay mas de una tarjeta para la persona, a la primera q encuentro la cambio de estado y al resto le doy de baja
       while found loop
      
         SELECT INTO resp cambiarestadotarjeta(latarjeta.idtarjeta , latarjeta.idcentrotarjeta,4);
           SELECT INTO elcupon *
                 FROM cupon
                 WHERE idcentrotarjeta =latarjeta.idcentrotarjeta and idtarjeta =latarjeta.idtarjeta;
           SELECT INTO resp cambiarestadocupon( elcupon.idcupon,elcupon.idcentrocupon ,4);
         
          fetch tarjetas into latarjeta;
       end loop;

    END IF;
    
   
    


RETURN resp;
END;
$function$
