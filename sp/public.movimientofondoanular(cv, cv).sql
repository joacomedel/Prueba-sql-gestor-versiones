CREATE OR REPLACE FUNCTION public.movimientofondoanular(character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
       tabla varchar;
       idtabla varchar;
       elidmovfondo bigint;
       elidcentromovfondo integer;
       elidprestamo  bigint;
       elidcentroprestamo integer;
       elmovfondo record;

BEGIN
       /*Este procedimiento recibe el nombre de la tabla y el id de la tabla */

      tabla = $1;
      idtabla = $2;

      if tabla ='prestamo' then
               /* Inicialmente tanto los prestamos como los planes de pago son tratados de la misma manera
                esta todo listo para configurar las cuentas y / o comportamiento diferente */
               SELECT INTO elidprestamo split_part(idtabla, '|',1)  ;
               SELECT INTO elidcentroprestamo split_part(idtabla, '|',2);
               
               SELECT INTO elmovfondo * FROM informemovfondofinanciacion
               WHERE idcentroprestamo = elidcentroprestamo and  idprestamo = elidprestamo;
               IF FOUND THEN
                        elidmovfondo = elmovfondo.idinformemovfondo;
                        elidcentromovfondo = elmovfondo.idcentroinformemovfondo;

               ELSE
                   SELECT INTO elmovfondo * FROM informemovfondoplanpago
                   WHERE idcentroprestamo = elidcentroprestamo and  idprestamo = elidprestamo;
                   elidmovfondo = elmovfondo.idinformemovfondo;
                   elidcentromovfondo = elmovfondo.idcentroinformemovfondo;
               END IF;

       END IF;
       UPDATE informemovfondoestado SET imfefechafin = now()
       WHERE nullvalue(imfefechafin) and idinformemovfondo = elidmovfondo and idcentroinformemovfondo=elidcentromovfondo;
       INSERT INTO informemovfondoestado (idestadotipo,idinformemovfondo,idcentroinformemovfondo,imfedescripcion) VALUES
       (4,elidmovfondo,elidcentromovfondo, 'Generado Automaticamente desde SP movimientofondoanular x anulacion del prestamo');

  RETURN true;
END;
$function$
