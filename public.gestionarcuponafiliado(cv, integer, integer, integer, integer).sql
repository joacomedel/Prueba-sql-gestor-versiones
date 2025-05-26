CREATE OR REPLACE FUNCTION public.gestionarcuponafiliado(character varying, integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
      elcupon RECORD;
      resp boolean;
      elnrodoc character varying;
      eltipodoc integer;
      elidestadotipo integer;
      uncuponbenef RECORD;
      cuponbenef refcursor;
      elcuponentregar  RECORD;
      elidcupon  integer;
      aux   RECORD;
      elidcentrocupon  	integer;
      ccuponmodifica refcursor;
      rcuponmodifica  RECORD;



BEGIN
     elnrodoc =$1;
     eltipodoc =$2;
     elidestadotipo= $3;
     elidcupon =$4;
     elidcentrocupon =$5;
     resp = true;

     -- Busco la tarjeta del afiliado que se encuentra en circulacion (que no fue dada de baja idestadotipo <> 4; )
    /* SELECT into elcupon *
     FROM  cupon
     NATURAL JOIN  tarjeta
     NATURAL JOIN cuponestado
     NATURAL JOIN persona
     WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and nullvalue(cefechafin) and idestadotipo <> 4;
*/
--Dani modifico el 06082015
SELECT into aux *
          FROM    tarjeta  NATURAL JOIN persona NATURAL JOIN  cupon
          JOIN tarjetaestado
           on(tarjeta.idtarjeta=tarjetaestado.idtarjeta and  
             tarjeta.idcentrotarjeta=tarjetaestado.idcentrotarjeta)
           JOIN cuponestado
           on(cupon.idcupon=cuponestado.idcupon and cupon.idcentrocupon=cuponestado.idcentrocupon)

 WHERE nrodoc=elnrodoc and tipodoc=eltipodoc and nullvalue(tefechafin) and fechafinos>=current_date
    and tarjetaestado.idestadotipo <> 4;

--     1    solicitado
--     2    CONFECCIONADO
--     3    ENTREGADO
--     4    De BAJA
    IF FOUND THEN
              IF (elidestadotipo = 1 )THEN
                 -- Se crea un nuevo cupon
                 SELECT INTO resp crearcupon(aux.idtarjeta,aux.idcentrotarjeta);
              END IF;
              IF ( elidestadotipo = 3) THEN  --Entregando cupones

                            if (not nullvalue(elidcupon) and not nullvalue(elidcentrocupon) and  elidestadotipo = 3  )THEN
                                    SELECT INTO elcuponentregar *
                                    FROM cupon
                                    NATURAL JOIN cuponestado
                                    WHERE nullvalue(cefechafin) and idestadotipo <> 4
                                          and idcentrocupon =elidcentrocupon and   idcupon = elidcupon  ;

                                    --- Busco todos los cupones del afiliado que tienen fechafin menor a la del cupon que se esta entregando asi se entregan
                                    OPEN ccuponmodifica FOR SELECT  *
                                           FROM tarjeta
                                           NATURAL JOIN cupon
                                           NATURAL JOIN cuponestado
                                           WHERE cfechavto <= elcuponentregar.cfechavto
                                                 and nullvalue(cefechafin) and idestadotipo < 3
                                                and nrodoc =elnrodoc and   tipodoc = eltipodoc  ;
                                     FETCH ccuponmodifica into rcuponmodifica;
                                     WHILE FOUND LOOP
                                           SELECT  INTO resp cambiarestadocupon(rcuponmodifica.idcupon , rcuponmodifica.idcentrocupon,elidestadotipo);
                                           FETCH ccuponmodifica into rcuponmodifica;
                                     END LOOP;
                                    close ccuponmodifica;


                            END IF;
             END IF;
             IF (elidestadotipo = 2    or elidestadotipo = 4) THEN

                            SELECT INTO resp cambiarestadocupon(aux.idcupon , aux.idcentrocupon,elidestadotipo);
                          

              END IF;
     ELSE resp = false;
    END IF;
RETURN resp;
END;
$function$
