CREATE OR REPLACE FUNCTION ca.recalcularvaloresconcepto___1(integer, integer, integer, integer)
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
       montoform  record;
       codliquidacion integer;
       m double precision;
       f varchar;
BEGIN
     elmes = $1;
     elanio = $2;
     eltipo = $3;
     elempleado = $4;
     SET search_path = ca, pg_catalog;
     /* Verifico que no exista una liquidacion para ese mes y ese anio*/
     SELECT INTO rsliquidacion * FROM liquidacion WHERE limes= elmes and lianio=elanio and idliquidaciontipo=eltipo;
     IF NOT FOUND THEN
              salida = false; -- no existe una liquidacion para ese mes y ese año
     ELSE

          /* Recorro los concepto empleados que deben ser recalculados
          * son aquellos que dependen directamente del bruto
          * busco aquellos donde el porcentaje del concepto es <> 0
          */
           OPEN cursorconcepto FOR  SELECT  ca.conceptoempleado.*,ca.concepto.*
                                     from  ca.conceptoempleado
                                     NATURAL JOIN ca.concepto
                                     NATURAL JOIN ca.conceptotipo
                                     --NATURAL JOIN conceptoliquidaciontipo
                                     WHERE  --idliquidaciontipo = eltipo and
                                         --   and (idconceptotipo=3 or  idconceptotipo = 4 )
                                        --   and idconceptotipo <> 7 adicional extraordinario
                                          -- and idconceptotipo<> 8 deduaccion extraordinaria
                                    --   AND   idconceptotipo=3
                                       --   and idconceptotipo <> 11
                                            (ceporcentaje <> 0 or idconceptotipo=11 or idconcepto=1)

                                           and  idliquidacion= rsliquidacion.idliquidacion
                                          and idpersona=elempleado
                                          order by ctordencalculo ASC;
           FETCH cursorconcepto INTO unconcepto;
           WHILE FOUND LOOP

                   /* Por cada concepto */
                   -- 0 actuualizo el valor de la unidad inicialmente con el valor que contiene porcentaje
                   -- Actualizo la unidad del concepto, en caso que se cambie por su formula quedara con el valor  que le corresponda
                  UPDATE conceptoempleado set ceunidad=unconcepto.ceporcentaje
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

                            if(unconcepto.idconceptotipo = 11 ) then
                            -- Si el tipo de concepto es variable se trata de un concepto que realiza acciones sobre otros
                            -- Las formulas a las que referencian los conceptos de to variable puede ser formulas que realizan
                            -- actualizaciones sobre otros conceptos o formulas como las de los demas conceptos
                            -- por lo que hay que ejecutar la formula a la que referencian
                           
                                   IF(unconcepto.idformula=8 or unconcepto.idformula=10 or unconcepto.idformula=39 or unconcepto.idformula=13 )THEN
                                         f =laformula; -- Esta formula debe ejecutarse (- Formula Especial-)

 -- IF (unconcepto.idformula=7) THEN RAISE NOTICE 'FROMUKA (%)',f; END IF;
                                   ELSE
                                       f = concat( 'UPDATE conceptoempleado set cemonto = (SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round( (t.monto + ' ,  unconcepto.comonto , ')::numeric, 5) END as monto from(' , laformula , ')as t)' , ' WHERE idpersona = ' , unconcepto.idpersona , ' and idconcepto =' , unconcepto.idconcepto , ' and idliquidacion =' , unconcepto.idliquidacion);
                                   END IF;
                            else
                            
                                 IF (unconcepto.idformula=7) THEN RAISE NOTICE 'FROMUKA (%)',laformula; END IF;
                                f = concat( 'UPDATE conceptoempleado set cemonto = (SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round( (t.monto + ' ,  unconcepto.comonto , ')::numeric, 5) END as monto from(' , laformula , ')as t)' , ' WHERE idpersona = ' , unconcepto.idpersona , ' and idconcepto =' , unconcepto.idconcepto , ' and idliquidacion =' , unconcepto.idliquidacion);
                              
                            end if;
                       
                           EXECUTE  f;
                       END IF;
                 END IF;
               FETCH cursorconcepto INTO unconcepto;
           END LOOP;
           CLOSE cursorconcepto;

           salida =true;
     END IF;

return 	salida;
END;
$function$
