CREATE OR REPLACE FUNCTION ca.liquidacionhaberesempleado(integer, integer, integer, date, date, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
* Este SP finaliza NO SE UTILIZA EN LA LIQUIDACION DE HABERES SE CREO POR CASO ESPECIAL
* CIERRE DE UNA LIQ PARTICULAR
*/
DECLARE
       elmes integer;
       elanio integer;
       eltipo integer;
       fechapago date;
       fechaliq date;
       rsliquidacion record;
       cursorconcepto refcursor;
       unconceptoempleado record;
       salida boolean;
       cursorempleado  refcursor;
       regformula record;
       laformulabruto varchar;
       laformuladeduc varchar;
       laformulaasigfam  varchar;
       laformulanorem varchar;
       montoform  record;
       auxcabecera record;
       codliquidacion integer;
          lapersona integer;
       m double precision;
       f varchar;
BEGIN
     elmes = $1;  -- mes de la liquidacion
     elanio = $2; -- anio de la liquidacion
     eltipo = $3; -- tipo de liquidacion
     fechapago = $4; -- fecha en la que se va a realizar el pago
     fechaliq = $5;  -- fecha en la que se realiza la liquidacion
     lapersona = $6; -- el id del empleado
     SET search_path = ca, pg_catalog;
     /* Verifico la existencia de una liquidacion para ese mes y ese anio*/
     SELECT INTO rsliquidacion * FROM liquidacion WHERE limes= elmes and lianio=elanio and idliquidaciontipo=eltipo;
     IF NOT FOUND THEN
              salida = false; -- no existe una liquidacion para ese mes y ese anio
     ELSE
            /* Actualizo los datos de la liquidacion una vez cerrada
            UPDATE liquidacion SET lifechapago = fechapago  , lifecha = fechaliq  WHERE idliquidacion =rsliquidacion.idliquidacion;
            */
           /* Recupera cada uno de los conceptos vinculados a la liquidacion*/
           OPEN cursorconcepto FOR
                  SELECT   DISTINCT idpersona ,idliquidacion
                  FROM conceptoempleado  WHERE idliquidacion = rsliquidacion.idliquidacion and idpersona=lapersona;

           FETCH cursorconcepto INTO unconceptoempleado;
           WHILE FOUND LOOP
                  -- Elimino de la relacion conceptoempleado aquellos conceptos que no influyen en la liquidacion del empleado
                  -- Es decir que se borran aquellos conceptos cuyo % = 0
                  DELETE FROM ca.conceptoempleado  WHERE  (idconcepto,idliquidacion,idpersona) IN(
                       SELECT idconcepto,idliquidacion,idpersona
                       FROM  ca.conceptoempleado NATURAL JOIN ca.concepto
                             WHERE idpersona = unconceptoempleado.idpersona
                             AND idconceptotipo<>11
                             AND  (ceporcentaje * cemonto)=0
                             AND idconcepto <>1
                             AND idliquidacion = rsliquidacion.idliquidacion );

                  codliquidacion = unconceptoempleado.idliquidacion;
                  -- obtengo el importe bruto :  adicionales + asignaciones familiares
                  -- idformula 21
                  SELECT INTO regformula * FROM formula WHERE idformula = 21;
                  laformulabruto = regformula.focalculo;
                  laformulabruto = reemplazarparametros(codliquidacion,eltipo,unconceptoempleado.idpersona,0,laformulabruto);

           		-- obtengo el importe No Remunerativo de la liquidacion

                  SELECT INTO regformula * FROM formula WHERE idformula = 46;
  				  laformulanorem = regformula.focalculo;
                  laformulanorem = reemplazarparametros(codliquidacion,eltipo,unconceptoempleado.idpersona,0,laformulanorem);



                  -- obtengo el importe de deducciones: deducciones + retenciones
                  -- id formula : 22
                  SELECT INTO regformula * FROM formula WHERE idformula = 22;
                  laformuladeduc = regformula.focalculo;
                  laformuladeduc = reemplazarparametros(codliquidacion,eltipo,unconceptoempleado.idpersona,0,laformuladeduc);

                  -- obtengo el importe en deducciones a partir de su formula
                  SELECT INTO regformula * FROM formula WHERE idformula = 30;
                  laformulaasigfam = regformula.focalculo;
                  laformulaasigfam = reemplazarparametros(codliquidacion,eltipo,unconceptoempleado.idpersona,0,laformulaasigfam);

                  /* La siguiente formula calcula el valor de los monto a partir de la ejecucion de las formulas obtenidas
                  Recordar que el neto es calculado como Bruto - Deducciones + Asignaciones familiares
                  */

                  f = concat('INSERT INTO ca.liquidacionempleado (idliquidacion, idpersona, leimpbruto, leimpdeducciones,leimpneto,leimpasignacionfam,leimpnoremunerativo)
                   VALUES ( ' , codliquidacion , ',' , unconceptoempleado.idpersona , ', ' ,
                   '(SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round(t.monto::numeric, 2)  END as monto
                   from(' , laformulabruto , ')as t) , '   , '(SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round(t.monto::numeric, 2)
                   END as monto from(' , laformuladeduc , ')as t) , '
                   , '(SELECT CASE WHEN nullvalue(t.monto)   THEN 0  ELSE round(t.monto::numeric, 2)  END as monto from('
                   , laformulabruto , ')as t)-
                   (SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round(t.monto::numeric, 2)  END as monto from(' , laformuladeduc , ')as t)
                   + ', '(SELECT CASE WHEN nullvalue(t.monto)   THEN 0  ELSE round(t.monto::numeric, 2)  END as monto from('
                   , laformulaasigfam , ')as t),
                   (SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round(t.monto::numeric, 2)  END as monto
                   from(' , laformulaasigfam , ')as t)
                   ,(SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round(t.monto::numeric, 2)  END as monto
                   from(' , laformulanorem , ')as t)
                   )');
                   --RAISE NOTICE 'Formula (%) ',f;
                 EXECUTE  f;

                 /*Genera la cabecera del recibo de sueldo. */
                 SELECT INTO auxcabecera * FROM ca.guardarliquidacioncabecera(codliquidacion, unconceptoempleado.idpersona );




               FETCH cursorconcepto INTO unconceptoempleado;
            END LOOP;
           CLOSE cursorconcepto;

           salida =true;
     END IF;

return 	salida;
END;
$function$
