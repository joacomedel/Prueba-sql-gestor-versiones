CREATE OR REPLACE FUNCTION ca.f_sacproporcional(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
        montototal DOUBLE PRECISION;
       valordia DOUBLE PRECISION;
       diastrabajados DOUBLE PRECISION;
       diaslicencia DOUBLE PRECISION;
       losdiaslab DOUBLE PRECISION;
       montobruto DOUBLE PRECISION;
       montonorem DOUBLE PRECISION;
       montopropsac DOUBLE PRECISION;
       elidconcepto INTEGER;
       cantdiastrabajdosinstitucion DOUBLE PRECISION;
       rlicenciamaternidad record;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_aguinaldo(#,&, ?,@)

--- Calcula la cantidad de dias tranajados por un empleado

SELECT INTO cantdiastrabajdosinstitucion ca.diastrabajdosinstitucion ($1, $2, $3, $4)+1;

IF (cantdiastrabajdosinstitucion >=180) THEN
   cantdiastrabajdosinstitucion=180;
ELSE
 /*   IF (cantdiastrabajdosinstitucion <=30) THEN
          cantdiastrabajdosinstitucion = 30;
    END IF;*/
 END IF;


SELECT INTO valordia (MAX(montomax)/360)
	FROM (
    SELECT (leimprem - (Case WHEN nullvalue(cemonto) THEN 0 ELSE cemonto END)) as montomax
	FROM (
      --COMENTE 04-1212    SELECT idliquidacion,(leimpbruto-leimpnoremunerativo)as leimprem
     --    SELECT idliquidacion,leimpbruto as leimprem
      SELECT idliquidacion,
             Case WHEN idliquidaciontipo = 1  THEN  (leimpbruto-(leimpnoremunerativo-leimpasignacionfam))
             WHEN  idliquidaciontipo = 2 THEN (leimpbruto-leimpasignacionfam) END as leimprem
	     FROM ca.liquidacionempleado
	     NATURAL JOIN ca.liquidacion
	     WHERE idpersona=$3 and
	           ( idliquidaciontipo =1 OR idliquidaciontipo=2) and
	           lianio = extract(YEAR from CURRENT_DATE)
	           and limes > extract(MONTH from CURRENT_DATE)-6
               order by lianio DESC, limes DESC
          limit 6
          ) AS B
	LEFT  JOIN   (
          SELECT idliquidacion,  SUM(cemonto*ceporcentaje )as cemonto
	      FROM ca.liquidacionempleado
	      NATURAL JOIN ca.liquidacion
	      NATURAL JOIN ca.conceptoempleado
	      WHERE idpersona=$3 and
	            ( idliquidaciontipo =1 OR idliquidaciontipo=2) and
	              lianio = extract(YEAR from CURRENT_DATE)
	              and (idconcepto =4 or idconcepto = 33)
          GROUP by idliquidacion,lianio, limes
          order by lianio DESC, limes DESC   limit 6
     )as P	USING (idliquidacion)
     ) as T;
     
     -- verifico si tiene alguna liquidacion y no es la primera del año
     IF( nullvalue(valordia)) THEN
                    -- SUMO todos los conceptos adicionales
                    SELECT INTO valordia SUM(cemonto * ceporcentaje)   FROM ca.conceptoempleado
                    NATURAL JOIN ca.concepto
                    WHERE idliquidacion = $1 and idpersona=$3 AND (idconceptotipo = 1 or idconceptotipo = 5 or idconceptotipo = 2) and idconcepto<>1070;
                    cantdiastrabajdosinstitucion = 5;
                    valordia = ((valordia /5)*30/360 );
                  --  CAMBIAR EL 5 X dias trabajado y el 30 x dias laborables
     END IF;
     
     
	
	/* Corroboro si la persona esta con licencia por maternidad  CREAR FORMULA 1105 */
    SELECT INTO rlicenciamaternidad SUM(ceporcentaje)as ceporcentaje
	FROM ca.conceptoempleado
    NATURAL JOIN ca.liquidacion
	WHERE idpersona = $3    and	idconcepto = 1105
          and lianio=extract(YEAR from CURRENT_DATE)
          and limes > extract(MONTH from CURRENT_DATE)-6;

    IF NOT nullvalue(rlicenciamaternidad.ceporcentaje) THEN -- tiene licencia por maternidad
                 SELECT INTO diastrabajados   ceporcentaje
	             FROM ca.conceptoempleado
	             WHERE idpersona = $3    and idconcepto = 1084 and --Dias trabajados
	                   idliquidacion=$1;
	
                --  Obtengo los dias laborables
                SELECT into losdiaslab  ceporcentaje
 	            FROM ca.conceptoempleado
	            WHERE idpersona = $3    and
			          idconcepto = 1045  and --Dias laborables mensuales
			          idliquidacion=$1;
	
                   --  montototal =  montototal * (cantdiastrabajdosinstitucion-diaslicencia);

                   montototal =  round ((cantdiastrabajdosinstitucion - rlicenciamaternidad.ceporcentaje)::numeric,3)*valordia;

                   --  montototal =cantdiastrabajdosinstitucion - rlicenciamaternidad.ceporcentaje;
                   --  montototal =  round ( ( ( montototal /abs(diastrabajados + diaslicencia) )*diastrabajados) ::numeric,5);


   ELSE
                   montototal  = valordia * cantdiastrabajdosinstitucion;
    END IF;
	

return montototal/0.5;

END;
$function$
