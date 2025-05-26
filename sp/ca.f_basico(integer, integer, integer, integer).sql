CREATE OR REPLACE FUNCTION ca.f_basico(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_basico(#,&, ?,@)
/*
ESTE SP si bien retorna un valor NO SE LO ASIGNA AL MONTO DEL CONCEPTO 1
ESTO SE DEBE porque el registro se encuentra bloqueado !!!!!
MODIFICAR EL RECALCULAR para que ejecute directamente los SP y no generer las instrucciones de EXECUTE
*/
elmonto = 0;
   SELECT INTO elmonto CASE WHEN nullvalue(ceporcentaje * cemonto) THEN 0 ELSE (ceporcentaje * cemonto) END
   FROM ca.conceptoempleado
   WHERE idliquidacion=$1 AND  idpersona =$3 AND 	idconcepto = 0;

   UPDATE ca.conceptoempleado
    SET cemonto =elmonto
  -- Se actualiza el monto del concepto (basico por dias trabajados) con el valor correspondiente al --valor del dia
    WHERE   idpersona =$3 and idconcepto=1 and idliquidacion = $1;
    
   UPDATE  ca.conceptoempleado SET cemonto=elmonto
   WHERE idconcepto IN (
         SELECT idconcepto
         FROM ca.conceptoempleado
         NATURAL JOIN ca.mapeolicenciaconcepto
         WHERE idpersona = $3 AND idliquidacion =$1

         )
   AND  idpersona = $3 AND idliquidacion =$1
                  and idconcepto <> 1105 and idconcepto <>1112; -- se excluye la licencia por maternidad que es el valor del bruto
   
   
    UPDATE ca.conceptoempleado
    SET ceporcentaje =T.ceporcentaje
    FROM  (SELECT  ceporcentaje
         FROM ca.conceptoempleado
         WHERE  idpersona =$3 and idconcepto=998 and idliquidacion = $1   
    )as T
    WHERE   idpersona =$3 and idconcepto=1 and idliquidacion = $1;

    UPDATE ca.conceptoempleado
    SET ceunidad=T.ceporcentaje
    FROM  (SELECT  ceporcentaje
         FROM ca.conceptoempleado
         WHERE  idpersona =$3 and idconcepto=1 and idliquidacion = $1   
    )as T
    WHERE   idpersona =$3 and idconcepto=1 and idliquidacion = $1;
    
/*GUARDO EL VALOR DEL BASICO CORRESPONDIENTE A LA LIQUIDACION

    UPDATE ca.conceptoempleado
    SET cemonto=T.camonto
    FROM (SELECT  camonto
           
          FROM ca.persona
          NATURAL JOIN ca.categoriaempleado
          NATURAL JOIN ca.categoriatipoliquidacion
          NATURAL JOIN ca.categoriatipo
          WHERE idpersona = $3 and
                (idliquidaciontipo=1 or idliquidaciontipo=6 ) and
                CURRENT_DATE >= cefechainicio and
       	        (nullvalue(cefechafin) or CURRENT_DATE <=cefechafin ) and  idcategoriatipo = 1
    )as T
    WHERE   idpersona =$3 and idconcepto=999 and idliquidacion = $1;


*/
IF nullvalue(elmonto) THEN elmonto = 0; END IF;
    
return elmonto;
END;
$function$
