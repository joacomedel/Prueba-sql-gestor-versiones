CREATE OR REPLACE FUNCTION ca.procesarnovedad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
* Incorpora las novedades como conceptos de la liquidacion del empleado
*/
DECLARE
      elmes integer;
       elanio integer;
       eltipo integer;
       rsliquidacion record;
       cursornovedad refcursor;
       unanovedad record;
       salida boolean;
       codliquidacion integer;
       res  record;
      empactivo  record;
BEGIN


     SET search_path = ca, pg_catalog;
     OPEN cursornovedad FOR SELECT * FROM tempnovedadprocesar;
     FETCH cursornovedad INTO unanovedad;
     IF FOUND THEN
               elmes = unanovedad.nsmes;
               elanio = unanovedad.nsanio;
               eltipo = unanovedad.idliquidaciontipo;

              /* Verifico que  exista una liquidacion para ese mes y ese anio*/
               SELECT INTO rsliquidacion * FROM liquidacion WHERE limes= elmes and lianio=elanio and idliquidaciontipo=eltipo and nullvalue(lifecha);
               IF NOT FOUND THEN
                      salida = false; -- no existe una liquidacion para ese mes y ese año iniciada
               ELSE
                      codliquidacion =rsliquidacion.idliquidacion;
                       WHILE FOUND LOOP
                             -- Si el empleado ya tiene ese concepto se elimina y se vuelve a insertar
               --       DELETE FROM conceptoempleado
                --                     WHERE limes= elmes and lianio=elanio --and idliquidaciontipo=eltipo and idconcepto=unanovedad.idconcepto;
                -- SOLO SI ES UN EMPLEADO ACTIVO SE INGRESA LA NOVEDAD
                              SELECT  into empactivo * FROM ca.categoriaempleado
                              WHERE idpersona = unanovedad.idpersona --and (cefechafin >= NOW() or nullvalue(cefechafin));
                              and ( cefechafin>=concat(elanio,'-',elmes,'-','01')::date or nullvalue(cefechafin) ) ;
               
                               IF  FOUND THEN
                                      delete from conceptoempleado
                                      where idliquidacion=codliquidacion and idconcepto=unanovedad.idconcepto
                                      and idpersona=unanovedad.idpersona;
                                      INSERT INTO conceptoempleado (idpersona,idconcepto,cemonto,ceporcentaje,idliquidacion)
                                      VALUES(unanovedad.idpersona, unanovedad.idconcepto, unanovedad.nsmontoconcepto,  unanovedad.nsporcentajeconcepto,
                                      codliquidacion);
                                      -- Recalcula los valores de los concepto de los empleados con novedades
                                      SELECT INTO res * from  ca.recalcularvaloresconcepto (elmes, elanio, eltipo,unanovedad.idpersona);
                               END IF;
                             FETCH cursornovedad INTO unanovedad;
                        END LOOP;

                salida=true;
                END IF;
               
      END IF;
 return salida;
END;
$function$
