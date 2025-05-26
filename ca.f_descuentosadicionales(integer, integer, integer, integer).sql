CREATE OR REPLACE FUNCTION ca.f_descuentosadicionales(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
     
       montodescuentoafil  DOUBLE PRECISION;
    
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

              
               
             SELECT INTO  montodescuentoafil CASE WHEN nullvalue (SUM(ceporcentaje * cemonto) ) then 0
                       ELSE SUM(ceporcentaje * cemonto) END
                      FROM ca.conceptoempleado
                      WHERE idpersona=$3 and idliquidacion =$1 and
                            (idconcepto = 387  -- Cta. Cte Asistencial
                            or idconcepto = 388 --Cta. Cte Asistencia Farmacia
                            or idconcepto = 991 -- Cta Prestamo Amuc
                            or idconcepto =  990  -- INPACO - Devolución ayuda económica
			    or idconcepto =  360  --Cuota Turismo Social
				or idconcepto =  374  -- Cuota Plan pago cta cte
				or idconcepto =  987  -- Valor Horas
				or idconcepto =  993  -- Seg.Vida
				or idconcepto =  1187  -- APUNC-Descuento
				or idconcepto =  1021  -- Anticipo Haberes

                            
                      ) ;

               


return montodescuentoafil;
END;
$function$
