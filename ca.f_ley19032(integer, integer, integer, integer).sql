CREATE OR REPLACE FUNCTION ca.f_ley19032(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       montominfarm DOUBLE PRECISION;
       elmonto DOUBLE PRECISION;
       elmontotope record;
       rbasico RECORD;
       rdiaslaborables RECORD;
       rconceptoempleado RECORD;
       rdiasjornadasemanal RECORD;
       rdiastrabajados RECORD;
       laliquidacion RECORD;
       laliquidacionregular record;
       rconceptoemp RECORD;
       aux record;
       tope DOUBLE PRECISION;
       valorsacpropor DOUBLE PRECISION;
       nuevotope DOUBLE PRECISION;
      elmontoext DOUBLE PRECISION;

BEGIN
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

 
valorsacpropor=1;
nuevotope =0;
elmonto=0;
elmontoext=0;

      --- Me fijo si se trata de una liq extraordinaria y que el monto no se exceda del tope
     SELECT INTO laliquidacion * FROM ca.liquidacion WHERE idliquidacion= $1;

--busco la liq actual de tipo Sueldo Sosunc
 SELECT INTO laliquidacionregular * FROM ca.liquidacion WHERE nullvalue(lifechapago) and idliquidaciontipo=1;



--el 28062022 JE aviso que en el caso de liqudiar el concepto 1070 SAC Proporcional, el tope es tope +sac/2
-- Busco los datos del concept SAC Proporcional
            SELECT INTO aux *
            FROM ca.conceptoempleado
            WHERE idpersona =$3
                     AND idliquidacion = $1
                     AND idconcepto = 1070 ; --S.A.C. Proporcional

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


     nuevotope = elmontotope.ctmontomaximo*valorsacpropor;
          
                                          
     select into rconceptoempleado * 
     FROM ca.conceptoempleado
     NATURAL JOIN ca.concepto
     NATURAL JOIN ca.liquidacion
     WHERE idpersona= $3 and idconcepto = 1070 AND idliquidacion = $1
           and (0 <>ceporcentaje * cemonto );
 
     IF FOUND THEN
 --caso 1
               SELECT INTO elmonto  CASE WHEN ((idliquidaciontipo =1 or idliquidaciontipo =2) and SUM(cemonto*ceporcentaje) >=nuevotope )
               THEN  nuevotope 
                 WHEN ((idliquidaciontipo =3 or idliquidaciontipo =4) and SUM(cemonto*ceporcentaje) >= (nuevotope /2)) THEN  (nuevotope /2)
                 ELSE  SUM(cemonto*ceporcentaje)
                 END
               FROM ca.conceptoempleado
               NATURAL JOIN ca.concepto
               NATURAL JOIN ca.liquidacion
               WHERE idpersona= $3 and idconcepto <>1051--(Zona desfavorable)
                      and (idconceptotipo = 1--(Adicionales) 
                           OR idconceptotipo =7--(Adicional extraordinario)
                           OR idconceptotipo =2--(Suplementos)
                           OR  idconceptotipo = 5--(Basicos)
                           OR idconceptotipo =10)
                      and idliquidacion= $1
                       and idconcepto<>1232
               group by idliquidacion,idliquidaciontipo;

   
     ELSE

               SELECT INTO elmonto CASE WHEN ((idliquidaciontipo =1 or idliquidaciontipo =2) and SUM(cemonto*ceporcentaje) >= nuevotope ) THEN  nuevotope 
                               WHEN ((idliquidaciontipo =3 or idliquidaciontipo =4) and SUM(cemonto*ceporcentaje) >= (nuevotope /2)) THEN  (nuevotope /2)
                          
                               ELSE  SUM(cemonto*ceporcentaje)  END
               FROM ca.conceptoempleado
               NATURAL JOIN ca.concepto
               NATURAL JOIN ca.liquidacion
               WHERE idpersona= $3 and idconcepto <>1051
                     and (idconceptotipo = 1 OR idconceptotipo =7 OR idconceptotipo =2 OR  idconceptotipo = 5
                     OR  idconceptotipo =10 )
                     and idliquidacion= $1
                      and idconcepto<>1232
               group by idliquidacion,idliquidaciontipo;
--esto se debe reemplazar por algo generico q pregunte si debe obtener un valor en elmontoextenero
if ( laliquidacion.idliquidaciontipo=6 and   nullvalue(laliquidacion.lifechapago)) then 
 
      SELECT INTO elmontoext CASE WHEN ((idliquidaciontipo =1 or idliquidaciontipo =2) 
              and SUM(cemonto*ceporcentaje) >= nuevotope ) THEN  nuevotope 
                               WHEN ((idliquidaciontipo =3 or idliquidaciontipo =4) 
               and SUM(cemonto*ceporcentaje) >= (nuevotope /2)) THEN  (nuevotope /2)
                          
                               ELSE  SUM(cemonto*ceporcentaje)  END
               FROM ca.conceptoempleado
               NATURAL JOIN ca.concepto
               NATURAL JOIN ca.liquidacion
               WHERE idpersona= $3 and idconcepto <>1051
                     and (idconceptotipo = 1 OR idconceptotipo =7 OR idconceptotipo =2 OR  idconceptotipo = 5
                     OR  idconceptotipo =10 )
                    and idliquidaciontipo=6 and nullvalue(laliquidacion.lifechapago)
                      and idconcepto<>1232
               group by idliquidacion,idliquidaciontipo;
  END IF;   
  END IF;
     /* VERIFICO SI SE TRATA DE UNA LIQ DE FARMACIA*/
     
     if($2 = 2 and $4 = 35)then
 
         -- Dani 20-01-2015  
            SELECT INTO rdiaslaborables *
            FROM ca.conceptoempleado
            WHERE idpersona =$3
                     AND idliquidacion = $1
                     AND idconcepto = 1045 ;
            
        
            SELECT INTO rdiastrabajados *
            FROM ca.conceptoempleado
            WHERE idpersona =$3
                     AND idliquidacion = $1
                     AND idconcepto = 998;

            SELECT INTO rdiasjornadasemanal *
            FROM ca.conceptoempleado
            WHERE idpersona =$3
                     AND idliquidacion = $1
                     AND idconcepto = 1136 ;
    --si tiene jornada reducida o si tiene jornada completa y ademas trabajo 30 dias entonces se le retiene sobre lo
    --   remunerativo    

    --si tiene jornada completa pero trabajo menos de 30 dias
         if  (rdiasjornadasemanal.ceporcentaje=44)and(rdiastrabajados.ceporcentaje<30) 
         
         then
             montominfarm = ((4*959.01)/rdiaslaborables.ceporcentaje * rdiastrabajados.ceporcentaje) ;
         else 
         montominfarm =0;
         end if;

--montominfarm = (rbasico.cemonto * rdiaslaborables.ceporcentaje) * 0.6666;      

     IF( montominfarm > elmonto )THEN
              elmonto = montominfarm;
     END IF;

     END IF;--fin si es idlquidaciontipo=2

     
     if (nullvalue(elmonto)) then elmonto=0; end if;
      IF  (not nullvalue(laliquidacion.idliqcomplementaria) or laliquidacion.idliquidaciontipo=6)THEN -- se trata de una liq complementaria
            
        
            -- 1 busco monto liquidado en la liquidacion regular de Marzo 2024 por pedido de JE
           --se deja la condicion que sea la liq 836 pq fue un caso especial que tenia que funcionar de manera diferente para no tener que  rectificar el 931 en Marzo 2024
--- OJO conceptualmente lo que se debe tener encuenta es que: los impuestos de LEY tienen en cuenta los topes del mes en que se esta realizando la liquidacion (es decir mes actual y anio actual). 
--Para el caso de Marzo 2025 surge la necesidad de hacer liq ext para Enero/2025 y Febrero/2025 
--La liq ext de Febrero tiene q tener en cuenta el tope de marzo +tope ext enero  
       
         
  SELECT INTO rconceptoemp * FROM ca.conceptoempleado WHERE idconcepto = 201 and idpersona= $3    and idliquidacion=laliquidacionregular.idliquidacion; 
            IF FOUND THEN
                  -- RAISE NOTICE 'el valor retornado es % en la liquidacion %' ,  elmonto, $1;
               tope = (elmontotope.ctmontomaximo ) - rconceptoemp.cemonto ;
               -- RAISE NOTICE 'el valor tope maximo % en la rconceptoemp.cemonto %' ,  elmontotope.ctmontomaximo, rconceptoemp.cemonto;
                 
                
             
               if(tope<=0) then --ya se desconto todo en la liq regular 
                    elmonto=0; 
               else  
                     
                      if((rconceptoemp.cemonto/*bruto marzo*/+elmonto+elmontoext)>nuevotope) then 
                        --si Bruto Marzo+Bruto Ext  superan tope marzo
                        -- elmonto=nuevotope-elmontoext-rconceptoemp.cemonto;   
                        if(laliquidacion.idliquidaciontipo=6) then 
                                 elmonto=nuevotope-rconceptoemp.cemonto;

                         else  
                                 elmonto=nuevotope-rconceptoemp.cemonto-elmontoext;
                         END IF;  
                         if(elmonto<=0) then --ya se desconto todo en la liq regular 
                                  elmonto=0; 
                                 END IF;                      
                        --caso contrario seria bruto marzo+ bruto ext n osuperan tope marzo ahi devuelve bruto ext q esta en elmonto
                          RAISE NOTICE 'AL PASAR POR ACA %' ,  elmonto;     
                      END IF;

               end if;  
            END IF;
     END IF;
    RAISE NOTICE 'el valor retornado es %' ,  elmonto;

 return elmonto;
END;
$function$
