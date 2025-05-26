CREATE OR REPLACE FUNCTION ca.f_vacacionesnogozadas(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       montobruto DOUBLE PRECISION;
       montonorem DOUBLE PRECISION;
       montoexcluidos DOUBLE PRECISION;
       montoremunerativo DOUBLE PRECISION;
       cantdiasvac INTEGER;
       montototal DOUBLE PRECISION;
       diasaliquidar INTEGER;
       rlicenciamaternidad record;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--(09:42:52) Silvia Cazador (int. 50):
--el 1068 seria la suma de los conceptos remunerativos menos el premio/25 por la cantidad de dias de vacaciones no gozadas...
--- Calculo el importe remunerativo correspondiente a la liquidacion del empleado
            -- importe del bruto
            SELECT INTO montobruto * FROM  ca.f_bruto($1,$2,$3,$4);
            -- obtengo el importe No Remunerativo de la liquidacion
            SELECT INTO montonorem * FROM  ca.f_noremunerativo($1,$2,$3,$4);
            -- obtengo el importe del premio correspondiente a la liq
            SELECT INTO montoexcluidos SUM(ceporcentaje * cemonto)  FROM ca.conceptoempleado
            WHERE (idconcepto = 1070  or idconcepto = 4 )  and idliquidacion=$1 and idpersona=$3;

            montoremunerativo = montobruto - montonorem;
            elmonto = montoremunerativo - montoexcluidos;


-- Obtengo la cantidad de dias que se estan liquidando al empleado
-- Se calcula el valor remunerativo diario
           SELECT INTO diasaliquidar  (ceporcentaje * cemonto) FROM  ca.conceptoempleado WHERE idconcepto = 998  and idliquidacion=$1 and idpersona=$3;
           elmonto = (((elmonto / diasaliquidar)*30)/25);
      
-- Obtengo la cantidad de dias de vacaciones no gozadas
           SELECT INTO cantdiasvac (ceporcentaje * cemonto) FROM ca.conceptoempleado WHERE idconcepto = 1150 and idliquidacion=$1 and idpersona=$3;

/*Actualizo el porcentaje que debe tomar el concepto
           UPDATE ca.conceptoempleado  SET cemonto = cantdiasvac * elmonto
                  WHERE idconcepto = 1069  and idliquidacion=$1 and idpersona=$3;
*/
           montototal =  elmonto   ;
           if nullvalue (montototal) THEN montototal =0;
           END IF;
return montototal;
END;
$function$
