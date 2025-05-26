CREATE OR REPLACE FUNCTION ca.f_jubilacion(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
        elmonto DOUBLE PRECISION;
        elmontotope record;
        aux record;
        tope DOUBLE PRECISION;
        valorsacpropor DOUBLE PRECISION;
        rconceptoempleado RECORD;
        laliquidacion record;
        laliquidacionregular record;
        rconceptoemp record;
        nuevotope  DOUBLE PRECISION;
        elmontoext  DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

     --f_funcion(#,&, ?,@)

valorsacpropor=1;
nuevotope  =0;
elmonto=0;
elmontoext =0;
 SELECT INTO laliquidacion * FROM ca.liquidacion WHERE idliquidacion= $1;
   
--busco la liq actual de tipo Sueldo Sosunc
 SELECT INTO laliquidacionregular * FROM ca.liquidacion WHERE nullvalue(lifechapago) and idliquidaciontipo=1;
 


--el 28062022 JE aviso que en el caso de liqudiar el concepto 1070 SAC Proporcional, el tope es tope +sac/2
-- Busco los datos del concept SAC Proporcional
            SELECT INTO aux *
            FROM ca.conceptoempleado
            WHERE idpersona =$3
                     AND idliquidacion = $1
                     AND idconcepto = 1070 ;
 
 if (found /*and (laliquidacion.idliquidaciontipo=3 or laliquidacion.idliquidaciontipo=4)*/  )then
--Dani 2025-02-27 volvio a revertir por pedido de JE. pq segun averiguaciones ante Afip corresponde que siempre q se descuente el concepto 1070 
--hay q calculr por el 1.5
valorsacpropor =1.5;
else
valorsacpropor =1;
end if;



 -- 1- Buscar el tope vigente para el concepto

     select into elmontotope * 
     FROM ca.conceptotope
     WHERE  idconcepto = 201
            and nullvalue(ctfechahasta);


  nuevotope  =elmontotope.ctmontomaximo*valorsacpropor;
    RAISE NOTICE  'nuevotope %' , nuevotope ;
  
  select into rconceptoempleado * FROM ca.conceptoempleado
                                          NATURAL JOIN ca.concepto
                                          NATURAL JOIN ca.liquidacion
                                          WHERE idpersona= $3 and idconcepto = 1070 AND idliquidacion = $1
                                          and (0 <>ceporcentaje * cemonto );
   
  IF FOUND THEN
             --Dani agrego 25032024 para que tenga en cuenta las liquidaciones extraordinarias
               SELECT INTO elmonto  CASE WHEN ((idliquidaciontipo =1 or idliquidaciontipo =2 ) and SUM(cemonto*ceporcentaje) >= nuevotope   	 )
               THEN  nuevotope  
                 WHEN ((idliquidaciontipo =3 or idliquidaciontipo =4) and SUM(cemonto*ceporcentaje) >= (nuevotope  /2)) THEN  (nuevotope  /2)
                 ELSE  SUM(cemonto*ceporcentaje)
                 END
               FROM ca.conceptoempleado
               NATURAL JOIN ca.concepto
               NATURAL JOIN ca.liquidacion
               WHERE idpersona= $3 and idconcepto <>1051
                      and (idconceptotipo = 1
                           OR idconceptotipo =7
                           OR idconceptotipo =2
                           OR  idconceptotipo = 5
                           OR idconceptotipo =10)
                      and idliquidacion= $1
                      and idconcepto<>1232
               group by idliquidacion,idliquidaciontipo;

  RAISE NOTICE  'elmonto bruto %' , elmonto ;
      ELSE   

     SELECT INTO elmonto  CASE WHEN ((idliquidaciontipo =1 or idliquidaciontipo =2 ) and SUM(cemonto*ceporcentaje) >= nuevotope  ) THEN  nuevotope  	
                 WHEN ((idliquidaciontipo =3 or idliquidaciontipo =4) and SUM(cemonto*ceporcentaje) >= (nuevotope  /2)) THEN  (nuevotope  /2)
                 ELSE  SUM(cemonto*ceporcentaje)
                 END
     FROM ca.conceptoempleado
     NATURAL JOIN ca.concepto
     NATURAL JOIN ca.liquidacion
     WHERE idpersona= $3 and idconcepto <>1051
            and (idconceptotipo = 1
                OR idconceptotipo = 7
                OR idconceptotipo = 2
                OR  idconceptotipo = 5
                OR idconceptotipo =10)
            and idliquidacion= $1
             and idconcepto<>1232
     group by idliquidacion,idliquidaciontipo;

--busco las liq extraordinarias a tener en cuenta, q serian aquellas extraordinarias q estan abiertas 
if ( laliquidacion.idliquidaciontipo=6 and nullvalue(laliquidacion.lifechapago) ) then 
 RAISE NOTICE  'entro al if  laliquidacion.idliquidaciontipo=6 and nullvalue(laliquidacion.lifechapago) %' , elmonto ;

      SELECT INTO elmontoext CASE WHEN ((idliquidaciontipo =1 or idliquidaciontipo =2) 
            and SUM(cemonto*ceporcentaje) >= nuevotope ) THEN  nuevotope 
                               WHEN ((idliquidaciontipo =3 or idliquidaciontipo =4)
            and SUM(cemonto*ceporcentaje) >= (nuevotope /2)) THEN  (nuevotope /2)
                          
                               ELSE  SUM(cemonto*ceporcentaje)  END
               FROM ca.conceptoempleado
               NATURAL JOIN ca.concepto
               NATURAL JOIN ca.liquidacion
               WHERE idpersona= $3 and idconcepto <>1051
                     and (idconceptotipo = 1 OR idconceptotipo =7 OR idconceptotipo =2 OR idconceptotipo = 5 OR idconceptotipo =10 )
                     and idliquidaciontipo=6 and nullvalue(laliquidacion.lifechapago)   
                     and idconcepto<>1232
               group by idliquidacion,idliquidaciontipo;
    RAISE NOTICE  ' lo q quedo en elmontoext %' , elmontoext ;
 
     END IF;  
   END IF;
 if (nullvalue(elmonto)) then elmonto=0;   end if;

  
     --- Me fijo si se trata de una liq extraordinaria y que el monto no se exceda del tope
 IF  (not nullvalue(laliquidacion.idliqcomplementaria) or laliquidacion.idliquidaciontipo=6)THEN -- se trata de una liq complementaria
           -- 1 busco monto liquidado en la liquidacion regular de Marzo 2024 (liq 834 )por pedido de JE
           --se deja la condicion que sea la liq 836 pq fue un caso especial que tenia que funcionar de manera diferente para no tener que  rectificar el 931
--Para el caso de Marzo 2025 surge la necesidad de hacer liq ext para Enero/2025 y Febrero/2025
                    
     SELECT INTO rconceptoemp * FROM ca.conceptoempleado 
                                WHERE idconcepto = 200 and idpersona= $3       /*and idliquidacion=873*/
                                and idliquidacion=laliquidacionregular.idliquidacion;                          /*ver si esto va a fallar para el calculo del concepto 200 en la ext*/
            IF FOUND THEN
                   
               tope = (elmontotope.ctmontomaximo ) - rconceptoemp.cemonto ;
            RAISE NOTICE  ' lo q quedo en tope 1%' , tope ;
               if(tope=0) then --ya se desconto todo en la liq regular 
                    elmonto=0; 
             RAISE NOTICE  ' lo q quedo en elmonto 2%' , elmonto ;
                else  
                    --si Bruto de la Liq Sueldo actual+Bruto Ext superan el tope que afecta a la liq actual
                    if((rconceptoemp.cemonto+elmonto+elmontoext)>nuevotope)     then 
                          --ver si esto tmb se deberia aplicar a ext de farmacia
                         if(laliquidacion.idliquidaciontipo=6) then 
                                 elmonto=nuevotope-rconceptoemp.cemonto;

                         else  
                                 elmonto=nuevotope-rconceptoemp.cemonto-elmontoext;
                         END IF;  
                         RAISE NOTICE  ' lo q quedo en elmonto 3%' , elmonto ;
                                 if(elmonto<=0) then --ya se desconto todo en la liq regular 
                                  elmonto=0; 
                          RAISE NOTICE  ' lo q quedo en elmonto 4%' , elmonto ;
                                 END IF; 
                           --caso contrario seria bruto liq actual+ bruto ext no superan tope actual ahi devuelve bruto ext q esta en elmonto
                                  
                           END IF;

               end if;  
            END IF;
 END IF;


        
 return elmonto;
END;
$function$
