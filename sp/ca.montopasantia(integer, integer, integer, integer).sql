CREATE OR REPLACE FUNCTION ca.montopasantia(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a aquellos en los cuales solo se debe sumar lo dscontado en calidad de un concepto en particular
* PRE: el asiento debe estar creado

*/
DECLARE
      laformula varchar;
      laformulaaux varchar;
      elmes integer;
      elanio integer;
      eltipo integer;
      elconcepto integer;
      datoconcepto record;
      rdiaslaborablesmensuales record;
      rdiastrabajados record; 
      rcategoria record; 
     rliq record;
     
BEGIN
   
     SET search_path = ca, pg_catalog;
   /*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

   
  SELECT INTO rliq *
  FROM ca.liquidacion
  WHERE idliquidacion = $1 ;
--ver porq devuelve un importe cableado  
  -- solo se debe  recalcular si el empleado es un pasante

  SELECT INTO rcategoria * 
  FROM ca.categoriaempleado
  WHERE idpersona =$3 AND idcategoriatipo=1 AND idcategoria=21
        AND (nullvalue(cefechafin)OR cefechafin	>= concat(rliq.lianio,'-',rliq.limes,'-1')::date );
 
  IF FOUND THEN
 
         --- VAS 251023
         SELECT INTO datoconcepto * 
         FROM ca.categoriatipoliquidacion 
         WHERE idcategoria=21 and idliquidaciontipo=$2;
  

      -- Obtengo los dias laborables mensuales
         SELECT INTO rdiaslaborablesmensuales * 
         FROM ca.conceptoempleado
         WHERE    idpersona =$3 and idconcepto=1045 and idliquidacion=$1;
           
       
       
         -- Obtengo los dias trabajados
         SELECT INTO rdiastrabajados * 
         FROM ca.conceptoempleado
         WHERE    idpersona =$3 and idconcepto=1 and idliquidacion=$1;
           
       
         --RAISE NOTICE 'EL MONTO ESSS >>>>> (%)' ,datoconcepto.camonto;
         UPDATE  ca.conceptoempleado 
         SET cemonto =  datoconcepto.camonto / rdiaslaborablesmensuales.ceporcentaje
         WHERE  idpersona =$3 and idconcepto=1232  and idliquidacion=$1; 
       
         UPDATE  ca.conceptoempleado 
         SET ceporcentaje = rdiastrabajados.ceporcentaje
         WHERE  idpersona =$3 and idconcepto=1232  and idliquidacion=$1;


END IF;
return 123;

END;
$function$
