CREATE OR REPLACE FUNCTION public.ingresarconsumoturismo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* Funcion que ingresa el consumo de turismo para un afiliado en particular,
creando las cuotas que seran pagadas en cta cte */
DECLARE

 elprestamo RECORD;
 lascuotas refcursor;
 unacuota RECORD;
 launidad RECORD;
 unvalor RECORD;
 elconsumo RECORD;
 laconfprest  RECORD;
 rconsumoturismovalores RECORD;
 rgrupoacompaniante RECORD;
 afiliado record;
 losacomp refcursor;
 losvalores refcursor;
 unacomp RECORD;
 idelprestamo BIGINT;
 idconsumo BIGINT;
 cuentacontable VARCHAR;
 movconceptocuota VARCHAR;
 respuesta boolean;

BEGIN
     cuentacontable = '10363'; /*Alquileres a Cobrar*/
     SELECT INTO elconsumo * FROM tempconsumoturismo;

     SELECT INTO laconfprest * FROM tempconfiguracionprestamo;

     SELECT INTO launidad * FROM turismounidad WHERE turismounidad.idturismounidad = elconsumo.idturismounidad;

     /* Inserto los datos del prestamos */
     SELECT INTO elprestamo * FROM tempprestamo;


     /* En caso que se trate de una actualizacion de un consumo turismo elimino datos Grupo acompañante, consumoturismo valores
        para que se inserte la nueva informacion
     */
        IF (not  nullvalue (elconsumo.idconsumoturismo) )THEN
             UPDATE consumoturismovalores SET ctvborrado = true
             WHERE idconsumoturismo =elconsumo.idconsumoturismo and  idcentroconsumoturismo = elconsumo.idcentroconsumoturismo;

              UPDATE grupoacompaniante SET gaborrado = true
             WHERE idconsumoturismo =elconsumo.idconsumoturismo and  idcentroconsumoturismo = elconsumo.idcentroconsumoturismo;
        ELSE
             elconsumo.idcentroconsumoturismo = centro();
        END IF;

     /* Inserto los datos de las cuotas, una de las cuotas es el anticipo
     OPEN lascuotas FOR SELECT * FROM tempprestamocuotas;
     consumo en cuenta corriente
     */

     IF (nullvalue(elconsumo.idconsumoturismo)
            and elconsumo.idformapago =3 )THEN
           SELECT INTO idelprestamo * FROM generarprestamocuotas(1);

     END IF;

     /* COnsumo con forma de pago efectivo */

     IF (nullvalue(elconsumo.idconsumoturismo)
            and elconsumo.idformapago =2 )THEN
         -- Ingresa la informacion del prestamo
            INSERT INTO prestamo(idprestamotipos, tipodoc, nrodoc,fechaprestamo,importeprestamo, idcentroprestamo)
            VALUES(1,laconfprest.tipodoc, laconfprest.nrodoc,NOW(),laconfprest.importetotal,Centro() );

            idelprestamo = currval('public.prestamo_idprestamo_seq');

            INSERT INTO prestamocuotas(idcomprobantetipos,idformapagotipos,idprestamo,idcentroprestamo,idcentroprestamocuota,importecuota,interes, anticipo,fechapagoprobable)
            VALUES (7,elconsumo.idformapago,idelprestamo, Centro(), Centro(),laconfprest.importetotal, 0,true,NOW());
     END IF;
          IF ( idelprestamo <> 0  OR NOT nullvalue(elconsumo.idconsumoturismo) ) THEN

              /* Inserto los datos del consumo de turismo */
               SELECT INTO elconsumo * FROM tempconsumoturismo;

               /* Si no hay un consumo se crea el nuevo */
               IF (nullvalue(elconsumo.idconsumoturismo ))THEN
                             INSERT INTO consumoturismo (idconsumoturismo,idcentroconsumoturismo,
                                    idprestamo,idcentroprestamo,ctfehcingreso,ctfechasalida,cantdias,idturismounidad,ctdescuento,
                                    ctinformacioncontacto,nrocuentac)
                              VALUES(nextval('public.consumoturismo_idconsumoturismo_seq'),centro(),idelprestamo,centro(),NOW(),NOW(),0
                              ,elconsumo.idturismounidad,elconsumo.descuento,elconsumo.ctinformacioncontacto
                              ,elconsumo.nrocuentac);
                              idconsumo = currval('public.consumoturismo_idconsumoturismo_seq');

                              INSERT INTO consumoturismoestado(idconsumoturismo,idcentroconsumoturismo,idconsumoturismoestadotipos)
                              VALUES(idconsumo,centro(),1); -- El estado 1 es Generado
               ELSE
                idconsumo = elconsumo.idconsumoturismo;
                UPDATE consumoturismo SET ctinformacioncontacto = elconsumo.ctinformacioncontacto
                WHERE idconsumoturismo = elconsumo.idconsumoturismo AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo;
               END IF;
               /* Ingreso los valores a  consumoturismovalores */
                OPEN losvalores FOR SELECT * FROM tempconsumoturismo;
                FETCH losvalores INTO unvalor;
                WHILE  found LOOP
                --Hay que verificar si hay que actualizar uno existente o crear nuevos o borrar los que no esten
                IF (nullvalue(elconsumo.idconsumoturismo ) )THEN
                       INSERT INTO consumoturismovalores(idconsumoturismo,
                       idcentroconsumoturismo,
                       fechaegreso,
                       fechaingreso,
                       ctvcantdias,
                       idturismounidadvalor
                       )VALUES(idconsumo,
                       centro(),
                       unvalor.fechaegreso,
                       unvalor.fechaingreso,
                       unvalor.cantdias,
                       unvalor.idturismounidadvalor
                       );
                ELSE
                -- Si es una modificacion, ya se marcaron como borrados todos.
                SELECT INTO rconsumoturismovalores * FROM consumoturismovalores
                            WHERE  idconsumoturismo = idconsumo
                            AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
                            AND idturismounidadvalor = unvalor.idturismounidadvalor;
                    IF FOUND THEN
                    UPDATE  consumoturismovalores SET
                           fechaegreso =  unvalor.fechaegreso,
                           fechaingreso = unvalor.fechaingreso,
                           ctvcantdias = unvalor.cantdias,
                           ctvborrado = FALSE
                           WHERE idconsumoturismo = idconsumo
                           AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
                           AND idturismounidadvalor = unvalor.idturismounidadvalor;
                    ELSE
                    INSERT INTO consumoturismovalores(idconsumoturismo,
                           idcentroconsumoturismo,
                           fechaegreso,
                           fechaingreso,
                           ctvcantdias,
                           idturismounidadvalor
                           )VALUES(idconsumo,
                           elconsumo.idcentroconsumoturismo,
                           unvalor.fechaegreso,
                           unvalor.fechaingreso,
                           unvalor.cantdias,
                           unvalor.idturismounidadvalor
                           );
                    END IF;

                END IF;


                FETCH losvalores INTO unvalor;
                END LOOP;
                CLOSE losvalores;


                /* Actualizacion de los datos del consumo */
                UPDATE consumoturismo SET ctfehcingreso=t.fingreso ,  ctfechasalida=t.fegreso , cantdias=t.cantd
                FROM (
                     SELECT MIN(fechaingreso)as fingreso, MAX(fechaegreso)as fegreso,SUM(ctvcantdias) as cantd
                     FROM consumoturismovalores
                     WHERE idconsumoturismo = idconsumo and idcentroconsumoturismo = centro()
                     )as t
                WHERE idconsumoturismo = idconsumo and idcentroconsumoturismo =centro();
                /*Calculo la cantidad de dias correctos*/
                UPDATE consumoturismo SET cantdias=ctfechasalida - ctfehcingreso
                WHERE idconsumoturismo = idconsumo and idcentroconsumoturismo =centro();
                /* Inserto los datos de las personas que acompañan */
                OPEN losacomp FOR SELECT * FROM tempgrupoacompaniante;
                FETCH losacomp INTO unacomp;
                WHILE  found LOOP
                IF (nullvalue(elconsumo.idconsumoturismo) )THEN
                       INSERT INTO grupoacompaniante(idconsumoturismo,idcentroconsumoturismo,nrodoc,tipodoc,nombres,apellido,fechanac,invitado,idvinculo)
                       VALUES(idconsumo,centro(),unacomp.nrodoc,unacomp.tipodoc,unacomp.nombres,unacomp.apellido,unacomp.fechanac,unacomp.invitado,unacomp.idvinculo);
                ELSE
                --Si es una modificacion, se marco como borrado a todos el grupo acompaniante
                     SELECT INTO rgrupoacompaniante * FROM grupoacompaniante
                     WHERE idconsumoturismo = elconsumo.idconsumoturismo
                           AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
                           AND nrodoc = unacomp.nrodoc
                           AND tipodoc = unacomp.tipodoc;
                     IF FOUND THEN
                        UPDATE grupoacompaniante SET
                               nombres = unacomp.nombres
                               ,apellido = unacomp.apellido
                               ,fechanac = unacomp.fechanac
                               ,invitado = unacomp.invitado
                               ,idvinculo = unacomp.idvinculo
                               ,gaborrado = FALSE
                        WHERE idconsumoturismo = elconsumo.idconsumoturismo
                           AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
                           AND nrodoc = unacomp.nrodoc
                           AND tipodoc = unacomp.tipodoc;
                     ELSE
                            INSERT INTO grupoacompaniante(idconsumoturismo,idcentroconsumoturismo,nrodoc,tipodoc,nombres,apellido,fechanac,invitado,idvinculo)
                            VALUES(elconsumo.idconsumoturismo,elconsumo.idcentroconsumoturismo,unacomp.nrodoc,unacomp.tipodoc,unacomp.nombres,unacomp.apellido,unacomp.fechanac,unacomp.invitado,unacomp.idvinculo);
                     END IF;
                END IF;

                FETCH losacomp INTO unacomp;
                END LOOP;
                CLOSE losacomp;
                /* Si el consumo turismo es nuevo se crea el informe*/
                  IF (nullvalue(elconsumo.idconsumoturismo) )THEN
                        /* Genero el informe de facturacion para Turismo*/
                        -- Recuperar la barra de la persona que corresponde a
                        SELECT INTO afiliado * FROM persona WHERE nrodoc = elprestamo.nrodoc and  tipodoc = elprestamo.tipodoc;

                        -- parametros : $1 idconsumoturismo.$2 idcentroconsumoturismo,  $3 nrodoc, $4 barra,  $5 numero cuenta contable, $6 importeTotal, $7 tipofactura, $8 sidevuelveanticipo
                        SELECT INTO respuesta * FROM  generarinformeturismo (idconsumo::integer, centro(), elprestamo.nrodoc, afiliado.barra::integer,cuentacontable, elprestamo.importeprestamo::real,'FA'::varchar,0,elconsumo.idformapago);
               END IF;
      END IF;
RETURN TRUE;
END;
$function$
