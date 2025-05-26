CREATE OR REPLACE FUNCTION ca.f_controlregretenciones(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       haberminimo DOUBLE PRECISION;
       montobruto DOUBLE PRECISION;
       montodescuentoley  DOUBLE PRECISION;
       montodescuentoafil DOUBLE PRECISION;
       montodisponible DOUBLE PRECISION;
       descembargo DOUBLE PRECISION;
       montodescuentounc DOUBLE PRECISION;
       canhorasd  DOUBLE PRECISION;
       cota1  DOUBLE PRECISION;
        cota2  DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;  
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

             
               --Dani actualizo el 11082022
               --haberminimo =45540 ;

              --Dani actualizo el 22092022 para que el haberminimo  sea un concepto mas para actualizar por sistema
        
               select  into haberminimo *  from ca.f_valorconceptofijo(1279);

               montodescuentoley=0;
               SELECT INTO montobruto ca.f_bruto($1, $2, $3, $4);

               SELECT INTO montodescuentoafil ca.f_descuentoafil($1, $2, $3, $4);
                  
               -- el método anterior devuelve todos los decuentos vinculados a un afiliado y estan incluidos en los descuentos de ley    
               -- SELECT INTO montodescuentoley ca.f_descuentoley($1, $2, $3, $4);
             
               montodisponible = montobruto - (montodescuentoley +montodescuentoafil );

               RAISE NOTICE 'montobruto... %',montobruto;
               RAISE NOTICE 'montodescuentoley... %',montodescuentoley;
               RAISE NOTICE 'montodescuentoafil... %',montodescuentoafil;
               RAISE NOTICE 'montodisponible la primera vez %',montodisponible;
 
               cota1 = 0.4 * montodisponible;
               RAISE NOTICE 'cota1 %',cota1;
 
               cota2 = haberminimo;
               RAISE NOTICE 'cota2 %',cota2;
 
               IF (cota1>cota2) THEN
                  montodisponible = cota1; -- Garantizo que los descuentos no van a exeder el 40% bruto menos retenciones
               RAISE NOTICE 'montodisponible la segunda vez  entrando por el if  %',montodisponible;
 
               ELSE
                   montodisponible =cota2; -- Garantizo que los descuentos no van a exeder el haber minimo
                   RAISE NOTICE 'montodisponible la segunda vez entrando por el else  %',montodisponible;
 
               END IF;
              
                SELECT INTO descembargo CASE WHEN nullvalue (SUM(ceporcentaje * cemonto) ) then 0
                       ELSE SUM(ceporcentaje * cemonto) END
                       FROM ca.conceptoempleado
                       WHERE  idconcepto = 1094 -- embargo judicial
                       and idpersona=$3 and idliquidacion =$1;
               montodisponible = montodisponible - descembargo;
			   RAISE NOTICE 'entro por... %',montodisponible;
 
               IF montodisponible >haberminimo THEN
                                 -- CONTROLAR QUE NO QUEDE EN 0 cuando se hacen los descuentos
                                 SELECT INTO montodescuentounc CASE WHEN nullvalue (SUM(ceporcentaje * cemonto) ) then 0
                                 ELSE SUM(ceporcentaje * cemonto) END
                                 FROM ca.conceptoempleado
                                 WHERE  idpersona=$3 and idliquidacion =$1
                                        and (idconcepto =387  --cta cte asistencial
                                        or idconcepto = 991  -- prestamo amuc
                                        or idconcepto = 990 -- prestamo inpaco
                                        or idconcepto =  360  -- turismo sosunc
                                        /*DAni agrego el 29-04-2015 los sig conceptos 
                                         segun pedido  Victor */
                                        or idconcepto =  374  -- Cuota Plan pago cta cte
					or idconcepto =  987  -- Valor Horas
					or idconcepto =  993  -- Seg.Vida
					or idconcepto =  1187  -- APUNC-Descuento
					or idconcepto =  1021  -- Anticipo Haberes
                                   );
                                  RAISE NOTICE 'entro por... %',montodisponible;
								 montodisponible = montodisponible - montodescuentounc;
              else
                montodisponible=0;
              END IF;




return montodisponible;
END;
$function$
