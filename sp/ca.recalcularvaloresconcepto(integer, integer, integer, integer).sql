CREATE OR REPLACE FUNCTION ca.recalcularvaloresconcepto(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
* Este SP es el que inicializa por primera vez la relacion entre empleado y concepto
* teiemdp em cuemta eñ valor retornado por la formula  vinculada al concepto
*/
DECLARE
       elmes integer;
       elanio integer;
       eltipo integer;
       elempleado integer;
       rsliquidacion record;
       cursorconcepto refcursor;
       unconcepto record;
       salida boolean;
       cursorempleado  refcursor;
       unempleado record;
       regformula record;
       laformula varchar;
       laformulaqinserta varchar;
       montoform  record;
       datoaeliminar record;
       codliquidacion integer;
       m double precision;
       f varchar;
       rusuario record;
       elidusuario integer;
BEGIN
     elmes = $1;
     elanio = $2;
     eltipo = $3;
     elempleado = $4;
     SET search_path = ca,public, pg_catalog;
     laformulaqinserta='';
     
     /* Se guarda la informacion del usuario que genero el comprobante */
      SELECT INTO rusuario * FROM public.log_tconexiones WHERE idconexion=current_timestamp;
      IF not found THEN
                   elidusuario = 25;
      ELSE
                    elidusuario = rusuario.idusuario;
      END IF;
     
     
     /* Verifico que no exista una liquidacion para ese mes y ese anio*/
     SELECT INTO rsliquidacion * 
     FROM liquidacion 
     WHERE limes= elmes and lianio=elanio and idliquidaciontipo=eltipo
                    AND nullvalue(lifechapago) AND nullvalue(lifecha) AND nullvalue(lifechapagoaporte) ; -- La liquidacion tiene que estar abierta para poder recalcular
     IF NOT FOUND THEN
              salida = false; -- no existe una liquidacion para ese mes y ese año ABIERTA 
     ELSE

          /* Recorro los concepto empleados que deben ser recalculados
          * son aquellos que dependen directamente del bruto
          * busco aquellos donde el porcentaje del concepto es <> 0
          */
           OPEN cursorconcepto FOR  SELECT  ca.conceptoempleado.*,ca.concepto.*
                                     from  ca.conceptoempleado
                                     NATURAL JOIN ca.concepto
                                     NATURAL JOIN ca.conceptotipo
                                    
                                     WHERE  
            --Dani agrego conceptotipo=1 para q tmb reclacule la unidad del conepto 1232 Asig Estimulo
                                            (ceporcentaje <> 0 or idconceptotipo=11 or idconcepto=1 or idconcepto=1232 or idconceptotipo=3 ) and
                                           idliquidacion= rsliquidacion.idliquidacion
                                          and idpersona=elempleado  
                                     ORDER BY ctordencalculo ASC;
           FETCH cursorconcepto INTO unconcepto;
           WHILE FOUND LOOP

         --VAS RAISE NOTICE 'entro al while';
                   /* Por cada concepto */
                   -- 0 actuualizo el valor de la unidad inicialmente con el valor que contiene porcentaje
                   -- Actualizo la unidad del concepto, en caso que se cambie por su formula quedara con el valor  que le corresponda
                      UPDATE conceptoempleado set ceunidad=unconcepto.ceporcentaje,                  
                         cefechamodificacion  =now() , idusuario=elidusuario
                   WHERE idconcepto=unconcepto.idconcepto and idpersona =unconcepto.idpersona
                        and idliquidacion=unconcepto.idliquidacion;

                   -- 1- Buscar el valor de la fórmula
                  laformula ='';
                  IF not nullvalue (unconcepto.idformula) THEN
                               SELECT INTO regformula * FROM formula WHERE idformula = unconcepto.idformula;
                               laformula = regformula.focalculo;



                 IF char_length(trim(laformula) )>0 THEN
                 -- 2 Solo se cambia el monto
                      laformula = reemplazarparametros(rsliquidacion.idliquidacion,eltipo,unconcepto.idpersona,unconcepto.idconcepto,laformula);
                       -- Al importe obtenido por la formula se suma el importe fijo si tiene el concepto

                      IF (unconcepto.idconceptotipo = 11 ) THEN
                            -- Si el tipo de concepto es variable se trata de un concepto que realiza acciones sobre otros
                            -- Las formulas a las que referencian los conceptos de to variable puede ser formulas que realizan
                            -- actualizaciones sobre otros conceptos o formulas como las de los demas conceptos
                            -- por lo que hay que ejecutar la formula a la que referencian
                           
                             IF(unconcepto.idformula=8 or unconcepto.idformula=10 or
                                unconcepto.idformula=39 or unconcepto.idformula=13
                                )THEN
                                     f =laformula; -- Esta formula debe ejecutarse (- Formula Especial-)
                             ELSE
                                 IF (unconcepto.idconcepto=1 or unconcepto.idconcepto=17 or
                                     unconcepto.idconcepto=33 or unconcepto.idconcepto=27 
                                    -- or unconcepto.idconcepto=1145 
                                   
                                     )then
                              --VAS         RAISE NOTICE 'aca (%)',laformula;
                                 ELSE
                                     f = concat( 'UPDATE conceptoempleado set cemonto = (SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round( (t.monto + ' ,  unconcepto.comonto , ')::numeric, 5) END as monto from(' , laformula , ')as t)' , ' WHERE idpersona = ' , unconcepto.idpersona , ' and idconcepto =' , unconcepto.idconcepto , ' and idliquidacion =' , unconcepto.idliquidacion);


                                 END IF;

                       END IF;
                 ELSE
                         


                     IF (unconcepto.idconcepto=1 or unconcepto.idconcepto=1232 or
                          unconcepto.idconcepto=17 or unconcepto.idconcepto=33
                          or unconcepto.idconcepto=27  --- VAS 30-07-2019 or unconcepto.idconcepto=1145
                          or unconcepto.idconcepto=1157
                          or unconcepto.idconcepto=1158
                       /*DAni agrega los conceptos 1282,1283,1284 porq sino produce un intento de doble update sobre el cemonto*/
                          or unconcepto.idconcepto = 1282
                          or unconcepto.idconcepto = 1283
                          or unconcepto.idconcepto = 1284
                          or unconcepto.idconcepto = 1253
                        /*****************************************************************************************************/

                           or unconcepto.idconcepto = 1207
                           or unconcepto.idconcepto = 10  
or unconcepto.idconcepto = 1280  


                          ) THEN
                           f =laformula;
                      --VAS      
 -- RAISE NOTICE 'aca (%)',laformula;
--  RAISE NOTICE 'aca el concepto  (%)',unconcepto.idconcepto;
                      ELSE
--t.monto +
                            f = concat( 'UPDATE conceptoempleado set cemonto = (SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round( (t.monto  + ' ,  unconcepto.comonto , ')::numeric, 5) END as monto from(' , laformula , ')as t)' , ' WHERE idpersona = ' , unconcepto.idpersona , ' and idconcepto =' , unconcepto.idconcepto , ' and idliquidacion =' , unconcepto.idliquidacion);
   
                      END IF;
               END IF;

           END IF;

       --VAS      RAISE NOTICE 'FROMUKA  del execute f (%)',f;
          EXECUTE  f;
      
          END IF;
               FETCH cursorconcepto INTO unconcepto;
         END LOOP;
           CLOSE cursorconcepto;
           salida =true;
    END IF;

RETURN 	salida;
END;
$function$
