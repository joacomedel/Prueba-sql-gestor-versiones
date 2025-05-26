CREATE OR REPLACE FUNCTION public.gestionarcuponafiliado1(character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	 elcupon RECORD;
	 resp boolean;
	 elnrodoc integer;
     eltipodoc integer;
     elidestadotipo integer;




BEGIN
     elnrodoc =$1;
     eltipodoc =$2;
     elidestadotipo= $3;
     resp = true;
     
     -- Busco la tarjeta del afiliado que se encuentra en circulacion (que no fue dada de baja idestadotipo <> 4; )
     SELECT into elcupon *
     FROM  cupon
     NATURAL JOIN  tarjeta
     NATURAL JOIN cuponestado
     WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and nullvalue(cefechafin) and idestadotipo <> 4;

--     1    solicitado
--     2    CONFECCIONADO
--     3    ENTREGADO
--     4    De BAJA
     IF FOUND THEN
              IF (elidestadotipo = 1 )THEN
                 -- Se crea un nuevo cupon
                 SELECT INTO resp crearcupon(elcupon.idtarjeta,elcupon.idcentrotarjeta);
              END IF;
              IF (elidestadotipo = 2 or  elidestadotipo = 3 or elidestadotipo = 4) THEN
                 SELECT INTO resp cambiarestadocupon(elcupon.idtarjeta , elcupon.idcentrotarjeta,elidestadotipo);
              END IF;
     ELSE resp = false;
    END IF;





RETURN resp;
END;
$function$
