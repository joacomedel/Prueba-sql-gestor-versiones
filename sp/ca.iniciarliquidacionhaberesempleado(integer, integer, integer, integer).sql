CREATE OR REPLACE FUNCTION ca.iniciarliquidacionhaberesempleado(integer, integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
* Este SP es el que inicializa por primera vez la relacion entre empleado y concepto
* teniendo en cuenta el valor retornado por la formula  vinculada al concepto
*/
DECLARE
       elmes integer;
       elanio integer;
       eltipo integer;
       lapersona integer;
       rsliquidacion record;
       cursorconcepto refcursor;
       unconcepto record;
       salida boolean;
       regformula record;
       laformula varchar;
       montoform  record;
       codliquidacion integer;
       m double precision;
       f varchar;
       rliq_ultima record;
       resp  boolean;
BEGIN
     elmes = $1;
     elanio = $2;
     eltipo = $3;
     lapersona = $4;
     salida = false; 
     SET search_path =pg_catalog, ca, public ;
     -- La liquidacion DEBE existir y estar abierta  VAS251023
     SELECT INTO rsliquidacion * 
     FROM liquidacion 
     WHERE limes= elmes and lianio=elanio and idliquidaciontipo=eltipo AND nullvalue(lifecha) ;
     IF FOUND THEN
             
                  codliquidacion =rsliquidacion.idliquidacion;
                 -- elimino si tiene algun concepto incorporado 
                 DELETE FROM conceptoempleado WHERE idliquidacion = codliquidacion and idpersona=lapersona;
      
                  -- Corroboro si existe alguna liquidacion para esa persona  VAS251023
                  SELECT INTO rliq_ultima * 
                  FROM ca.liquidacionempleado
                  NATURAL JOIN ca.liquidacion
                  WHERE idpersona = lapersona AND idliquidaciontipo = eltipo
                  ORDER BY idliquidacion DESC
                  LIMIT 1;
                  IF FOUND THEN ---  VAS251023 existe una liquidacion para ese empleado se retorna como referencia busco los conceptos liquidados
                         OPEN cursorconcepto FOR SELECT * 
                         FROM ca.conceptoempleado
                         NATURAL JOIN ca.concepto
                      --   NATURAL JOIN ca.conceptoliquidaciontipo
                         WHERE   idpersona = lapersona   -- del empleado

                                 AND idliquidacion = rliq_ultima.idliquidacion   -- ultima liquidacion
                                 AND activo  ---solo los conceptos que actualmente se encuentran activos;
                        ;



                  ELSE 
                         ---- No exite una liq y genero una desde 0 para configurar   
                   
                                   /* Recupera cada uno de los conceptos vinculados a la liquidacion*/
/*dani agrego el 28-05-2014  and idconceptotipo<>4 pporq intentaba insertar dos veces los conceptos de tipo asignacion*/
                                   OPEN cursorconcepto FOR
                                   SELECT  *  
                                   FROM ca.concepto
                                   NATURAL JOIN ca.conceptoliquidaciontipo
                                   WHERE activo and coautomatico
                                           and idliquidaciontipo = eltipo
                                           AND idconceptotipo<>7 and idconceptotipo<>8 and idconceptotipo<>4 order by  idconceptotipo asc;
                END IF;
                                   FETCH cursorconcepto INTO unconcepto;
                                   WHILE FOUND LOOP
                                          /* Por cada concepto */
                                          -- 1- Calcular valor concepto
                                          laformula ='';
                                          IF not nullvalue (unconcepto.idformula) THEN
                                                SELECT INTO regformula *
                                                FROM formula
                                                WHERE idformula = unconcepto.idformula;
                                                laformula = regformula.focalculo;
                                          END IF;
                                         /* por cada empleado insertar en la relacion concepto empleado para esa liquidacion*/
                                          IF ( (char_length(laformula )>0)and (unconcepto.idconceptotipo<>11)  )THEN
                                                laformula = reemplazarparametros(codliquidacion,eltipo,lapersona,unconcepto.idconcepto,laformula);
                                                  --  RAISE NOTICE 'Formula (%) ',laformula;
    --Dani modifico 2024-09-17 daba error unconcepto.ceporcentaje::text ya que no existe en la consulta previa
                                                f = concat('INSERT INTO ca.conceptoempleado (idpersona,idconcepto,cemonto,ceporcentaje,idliquidacion)VALUES ( '::text , lapersona::text , ','::text, unconcepto.idconcepto::text , ','::text, '(SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round(t.monto::numeric, 2)  END as monto from('::text , laformula::text , ')as t) ,' ::text , unconcepto.coporcentaje::text , ','::text, codliquidacion::text ,')'::text,''::text);
 
                                                 RAISE NOTICE 'Formula (%) ',f;
                                                 EXECUTE  f;

                                                -- Al importe obtenido por la formula se suma el importe fijo si tiene el concepto
                                                 UPDATE conceptoempleado set cemonto = cemonto + unconcepto.comonto
                                                 WHERE idpersona = lapersona
                                                       and idconcepto = unconcepto.idconcepto
                                                       and idliquidacion = codliquidacion;

                                          ELSE
                                         --Dani modifico 2024-09-17 daba error unconcepto.ceporcentaje::text ya que no existe en la consulta previa
   
                                              INSERT INTO conceptoempleado (idpersona,idconcepto,cemonto,ceporcentaje,idliquidacion)
                                             VALUES(lapersona,unconcepto.idconcepto,unconcepto.comonto,unconcepto.coporcentaje,codliquidacion);
                                          END IF;

                                FETCH cursorconcepto INTO unconcepto;
                                END LOOP;
                                CLOSE cursorconcepto;
           select INTO resp ca.recalcularvaloresconcepto(elmes,elanio,eltipo,lapersona) ;
           salida = true;
  END IF;

return 	salida;
END;$function$
