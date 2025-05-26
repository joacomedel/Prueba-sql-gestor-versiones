CREATE OR REPLACE FUNCTION ca.liquidacionhaberes(integer, integer, integer, date, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
* Este SP finaliza la liquidacion tomando los conceptos de la relacion conceptoempleado configurados para cada empleado
* Elimina todos aquellos conceptos cuyo valor=monto * porcentaje es igual a 0
* 
* NO ELIMINAR NINGUN TIPO DE INFORMACION EN ESTE PROCEDIMIENTO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
* 
*/
DECLARE
       elmes integer;
       elanio integer;
       eltipo integer;
       fechapago date;
       fechaliq date;
       rsliquidacion record;
       cursorconcepto refcursor;
       cursorempleadoseliminar refcursor;
       unconceptoempleado record;
       salida boolean;
       cursorempleado  refcursor;
       regformula record;
       regformularem record; 
       cursorunempeliminar record;
       laformulabruto varchar;
       laformuladeduc varchar;
       laformulaasigfam  varchar;
       laformulanorem varchar;
       laformularem varchar;
       montoform  record;
       auxcabecera record;
       codliquidacion integer;
       m double precision;
       f varchar;
BEGIN
     elmes = $1;  -- mes de la liquidacion
     elanio = $2; -- anio de la liquidacion
     eltipo = $3; -- tipo de liquidacion
     fechapago = $4; -- fecha en la que se va a realizar el pago
     fechaliq = $5;  -- fecha en la que se realiza la liquidacion

     SET search_path = ca, pg_catalog;
     /* Verifico la existencia de una liquidacion para ese mes y ese anio*/
     SELECT INTO rsliquidacion * FROM liquidacion WHERE limes= elmes and lianio=elanio and idliquidaciontipo=eltipo;
     IF NOT FOUND THEN
              salida = false; -- no existe una liquidacion para ese mes y ese anio
     ELSE
            /* Actualizo los datos de la liquidacion una vez cerrada*/
            UPDATE liquidacion SET lifechapago = fechapago  , lifecha = fechaliq  WHERE idliquidacion =rsliquidacion.idliquidacion;
     
           /* Recupera cada uno de los conceptos vinculados a la liquidacion*/
           OPEN cursorconcepto FOR
                  SELECT   DISTINCT idpersona ,idliquidacion FROM conceptoempleado  WHERE idliquidacion = rsliquidacion.idliquidacion ;

           FETCH cursorconcepto INTO unconceptoempleado;
           WHILE FOUND LOOP
                  -- Elimino de la relacion conceptoempleado aquellos conceptos que no influyen en la liquidacion del empleado
                  -- Es decir que se borran aquellos conceptos cuyo % = 0
                  DELETE FROM ca.conceptoempleado  WHERE  (idconcepto,idliquidacion,idpersona) IN(
                       SELECT idconcepto,idliquidacion,idpersona
                       FROM  ca.conceptoempleado NATURAL JOIN ca.concepto
                             WHERE idpersona = unconceptoempleado.idpersona
                             AND idconceptotipo<>11
                             AND   abs(ceporcentaje * cemonto)=0
                             AND idconcepto <>1
                             AND idliquidacion = rsliquidacion.idliquidacion );
/*Dani agrego el 2015-09-07 para resolver el problema de redondeo q no quieren q quede en el recibo*/
                       update  ca.conceptoempleado  
                 set cemontofinal =(ceporcentaje *cemonto)    WHERE 
                 (idconcepto,idliquidacion,idpersona) IN(
                       SELECT idconcepto,idliquidacion,idpersona
                       FROM  ca.conceptoempleado NATURAL JOIN ca.concepto
                             WHERE idpersona = unconceptoempleado.idpersona
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

-- obtengo el importe   Remunerativo de la liquidacion 
                
                  SELECT INTO regformula * FROM formula WHERE idformula = 132;
  				  laformularem = regformula.focalculo;
                  laformularem = reemplazarparametros(codliquidacion,eltipo,unconceptoempleado.idpersona,0,laformularem);



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

                  f = concat('INSERT INTO ca.liquidacionempleado (idliquidacion, idpersona, leimpbruto, leimpdeducciones,leimpneto,leimpasignacionfam,leimpnoremunerativo,leimpremunerativo)
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
                   ,(SELECT CASE WHEN nullvalue(t.monto) THEN 0  ELSE round(t.monto::numeric, 2)  END as monto
                   from(' , laformularem , ')as t)
                   )');
                   RAISE NOTICE 'Formula (%) ',f;






                 EXECUTE  f;

                   /*Genera la cabecera del recibo de sueldo. */
 RAISE NOTICE 'codliquidacion = (%)  idpersona =(%) ',codliquidacion , unconceptoempleado.idpersona;
              --vas141223  
   SELECT INTO auxcabecera * FROM ca.guardarliquidacioncabecera(codliquidacion, unconceptoempleado.idpersona );
                 
                   /*Dani agrego el 27/09/2016 para q las unidades del concepto antiguedad  sean 0.01*cant anios*/
                   /*select * from ca.calcularunidad(2,unconceptoempleado.idpersona,codliquidacion);*/
                   perform ca.calcularunidad(2,unconceptoempleado.idpersona,codliquidacion);

    

               FETCH cursorconcepto INTO unconceptoempleado;
            END LOOP;
           CLOSE cursorconcepto;

           /*VAS 14-03-2018 para que se generen las minutas correspondientes a la liquidacion que se esta cerrando*/ 
        --   perform ca.generarminutainstitucion(concat(elmes,'/',elanio));

    /*       SELECT ca.generarminutainstitucion(concat(elmes,'/',elanio))
           FROM (
                SELECT SUM(cantliq) as cantliq, SUM(cantcerradas) as cantcerradas 
                FROM (
                  SELECT count(*) as cantliq , 0 as cantcerradas
                  FROM ca.liquidacion
                  WHERE limes =elmes and lianio =elanio
                  UNION 
                  SELECT 0 as cantliq , count(*) as cantcerradas
                  FROM ca.liquidacion
                  WHERE limes =elmes and lianio =elanio 
                        and not nullvalue(lifechapagoaporte) and not nullvalue(lifechapago)
                ) as T
           ) as R
           WHERE cantliq = cantcerradas;*/


           -- vas 14-03-2018

           salida =true;
     END IF;

return 	salida;
END;
$function$
