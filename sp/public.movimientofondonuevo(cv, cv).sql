CREATE OR REPLACE FUNCTION public.movimientofondonuevo(character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
        tabla varchar;
        idtabla varchar;  -- si el id tiene mas de un campo se encuentra cada campo separado por |
        elprestamo record;
        elidprestamo bigint;
        elidcentroprestamo integer;
       idmovimientofondo bigint;
        eltipomovfondo integer;
        nroctacble varchar;
BEGIN
      /*Este procedimiento recibe el nombre de la tabla y el id de la tabla */
      
      tabla = $1;
      idtabla = $2;  
     
      if tabla ='prestamo' then
               /* Inicialmente tanto los prestamos como los planes de pago son tratados de la misma manera
                esta todo listo para configurar las cuentas y / o comportamiento diferente */

               SELECT INTO elidprestamo split_part(idtabla, '|',1)  ;
               SELECT INTO elidcentroprestamo split_part(idtabla, '|',2);



               SELECT INTO elprestamo *
               FROM prestamo
               WHERE idprestamo = elidprestamo and  idcentroprestamo = elidcentroprestamo;
               IF elprestamo.idprestamotipos = 3 THEN -- Plan de Pagos
                     eltipomovfondo = 1;
                     nroctacble = 10342;
               END IF;
               IF elprestamo.idprestamotipos = 4 THEN -- Asistencial
                      eltipomovfondo = 2;
                      nroctacble = 10342;
               END IF;
               
               INSERT INTO informemovfondo(idinformemovfondotipo)VALUES (eltipomovfondo);
               idmovimientofondo  = currval('informemovfondo_idinformemovfondo_seq');
               
               --- Ingreso el estado al movimiento de fondo
               INSERT INTO  informemovfondoestado(idestadotipo,idinformemovfondo,idcentroinformemovfondo,imfedescripcion)
                      VALUES (1,idmovimientofondo,centro(),'Generado automaticamente desde SP movimientofondonuevo');

               IF elprestamo.idprestamotipos = 3 THEN -- Plan de Pagos
                        INSERT INTO informemovfondoplanpago (idinformemovfondo, idcentroinformemovfondo,idcentroprestamo, idprestamo)
                                VALUES(idmovimientofondo,centro(),elidcentroprestamo, elidprestamo);
               END IF;
               IF elprestamo.idprestamotipos = 4 THEN -- Asistencial
                        INSERT INTO informemovfondofinanciacion(idinformemovfondo, idcentroinformemovfondo,idcentroprestamo, idprestamo)
                                VALUES(idmovimientofondo,centro(),elidcentroprestamo, elidprestamo);
               END IF;

               -- Se generan los item del informe de fondos
               -- un item por el importe total del prestamo
               INSERT INTO informemovfondoitem ( idinformemovfondo,idcentroinformemovfondo,nrocuentac, cantidad,importe,descripcion)
                      VALUES(idmovimientofondo,centro(),nroctacble,1,elprestamo.importeprestamo, concat('importe total prestamo ',idtabla));
             
               
      END IF;
      RETURN true;
END;
$function$
