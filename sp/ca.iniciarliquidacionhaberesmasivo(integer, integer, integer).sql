CREATE OR REPLACE FUNCTION ca.iniciarliquidacionhaberesmasivo(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
* Este SP es el que inicializa por primera vez la relacion entre empleado y concepto
* teiemdp em cuemta eñ valor retornado por la formula  vinculada al concepto
*/
DECLARE
       elmes integer;
       elanio integer;
       eltipo integer;
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

     SET search_path = ca, pg_catalog;
     /* Verifico que no exista una liquidacion para ese mes y ese anio*/
     SELECT INTO rsliquidacion * FROM liquidacion WHERE limes= elmes and lianio=elanio and idliquidaciontipo=eltipo;
     IF  FOUND THEN
              salida = false; -- ya existe una liquidacion para ese mes y ese anio
     ELSE
           INSERT INTO liquidacion (lianio,limes,idliquidaciontipo )VALUES(elanio,elmes,eltipo);
           codliquidacion = currval('ca.liquidacion_idliquidacion_seq');
         --  codliquidacion =353;
           /* Recupero cada uno de los empleados */
             OPEN cursorempleado FOR SELECT  *  FROM empleado;
               --WHERE idpersona =3;
                  FETCH cursorempleado INTO unempleado;
                  WHILE FOUND LOOP

                  /* Recupera cada uno de los conceptos vinculados a la liquidacion*/
                  OPEN cursorconcepto FOR
                  SELECT  *  FROM concepto NATURAL JOIN conceptoliquidaciontipo  WHERE activo and idliquidaciontipo = eltipo and idconceptotipo<>7 order by  idconceptotipo asc;

                  FETCH cursorconcepto INTO unconcepto;
                  WHILE FOUND LOOP
                         /* Por cada concepto */
                         -- 1- Calcular valor concepto
                         laformula ='';
                         IF not nullvalue (unconcepto.idformula) THEN
                               SELECT INTO regformula * FROM formula WHERE idformula = unconcepto.idformula;
                               laformula = regformula.focalculo;
                         END IF;


                        /* por cada empleado insertar en la relacion concepto empleado para esa liquidacion*/
                         IF char_length(laformula )>0 THEN
                                      laformula = reemplazarparametros(codliquidacion,eltipo,unempleado.idpersona,unconcepto.idconcepto,laformula);
                                  --    RAISE NOTICE 'Formula (%) ',laformula;
                                     f = concat('INSERT INTO ca.conceptoempleado (idpersona,idconcepto,cemonto,ceporcentaje,idliquidacion)VALUES ( ' , unempleado.idpersona , ',', unconcepto.idconcepto , ',', '(SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round(t.monto::numeric, 2)  END as monto from(' , laformula , ')as t) ,' , unconcepto.coporcentaje , ',', codliquidacion ,')');
                                     EXECUTE  f;

                                  -- Al importe obtenido por la formula se suma el importe fijo si tiene el concepto
                                      UPDATE conceptoempleado set cemonto = cemonto + unconcepto.comonto
                                      WHERE idpersona = unempleado.idpersona
                                            and idconcepto = unconcepto.idconcepto
                                            and idliquidacion = codliquidacion;

                         ELSE
                             INSERT INTO conceptoempleado (idpersona,idconcepto,cemonto,ceporcentaje,idliquidacion)
                             VALUES(unempleado.idpersona,unconcepto.idconcepto,unconcepto.comonto,unconcepto.coporcentaje,codliquidacion);
                         END IF;

               FETCH cursorconcepto INTO unconcepto;
               END LOOP;
               CLOSE cursorconcepto;
           FETCH cursorempleado INTO unempleado;
           END LOOP;
           CLOSE cursorempleado;
           salida =true;
     END IF;

return 	salida;
END;
$function$
