CREATE OR REPLACE FUNCTION ca.f_farmretcontribucion(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       rbasico record;
       rdiaslaborables record;
       rconceptoempleado record;
       rdiasjornadasemanal record;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_farmaguinaldo(#,&, ?,@)

         SELECT INTO elmonto   SUM(cemonto*ceporcentaje)
         FROM ca.conceptoempleado
         NATURAL JOIN ca.concepto
         WHERE idpersona =$3
               -- AND (idliquidacion =320 OR idliquidacion =322 )
               AND idliquidacion = $1
               AND idconceptotipo <> 3 -- 3	Retenciones
               AND idconceptotipo <> 4 -- Asignaciones Familiares
               AND idconceptotipo <> 8 -- Deduccion extraordinaria	
               AND idconceptotipo <> 11 -- Variables Globales
           --Dani  agrego los siguientes conceptos el 22-10-2015 por pedido de Julieta E.
           --a continuacion los conceptos a despreciar  en caso de liquidacion final
           --Dani  saca los siguientes conceptos el 28-10-2015 por pedido de Julieta E.
           --ya que segun lo visto en la ley, el concepto se calcula sobre la "Remuneracion Integral"
        /*    AND idconcepto <> 1068
              AND idconcepto <> 1069
              AND idconcepto <> 1197
              AND idconcepto <> 1198
        */
              AND idconcepto <> 1105
          
               --OR (idconcepto=1142 or idconcepto=1143 )
       ;
       
       -- Busco los datos del basico
       SELECT INTO rbasico *
       FROM ca.conceptoempleado
       WHERE idpersona =$3
             AND idliquidacion = $1
             AND idconcepto = 1028 ;
             
       -- Busco los datos de los dias laborables
       SELECT INTO rdiaslaborables *
       FROM ca.conceptoempleado
       WHERE idpersona =$3
             AND idliquidacion = $1
             AND idconcepto = 1045 ;
-- Dani 22-01-2015  
          
            SELECT INTO rdiasjornadasemanal *
            FROM ca.conceptoempleado
            WHERE idpersona =$3
                     AND idliquidacion = $1
                     AND idconcepto = 1136 ;

             
       -- Corroboro si a la persona se le liquida el concepto 1070
       SELECT INTO rconceptoempleado *
       FROM ca.conceptoempleado
       WHERE idpersona =$3
             AND idliquidacion = $1
             AND idconcepto = 1070;


 
       IF NOT FOUND THEN -- solicito Victor 26/06 con la liq de Paola
-- IF(rbasico.ceporcentaje < rdiaslaborables.ceporcentaje  
-- solicito Victor 26/08 con la liq de Ignacio

     --Si se trata de jornada parcial
     if  (rdiasjornadasemanal.ceporcentaje<44) then
         elmonto =  (rbasico.cemonto * rdiaslaborables.ceporcentaje) * 0.6666;
         
         /*    IF(rbasico.ceporcentaje < (0.6666)*rdiaslaborables.ceporcentaje  )THEN
                     elmonto =  (rbasico.cemonto * rdiaslaborables.ceporcentaje) * 0.6666;
                     -- elmonto = elmonto * 0.6666;
               END IF;
         */  
     END IF;

 END IF;
return elmonto;
END;
$function$
