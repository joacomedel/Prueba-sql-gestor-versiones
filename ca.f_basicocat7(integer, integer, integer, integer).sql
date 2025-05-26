CREATE OR REPLACE FUNCTION ca.f_basicocat7(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       elmontocat DOUBLE PRECISION;
       losdiaslab DOUBLE PRECISION;
       diaslicencia DOUBLE PRECISION;
        diastrabajados DOUBLE PRECISION;
       porcentajetrabajado DOUBLE PRECISION;
       elidconcepto integer;
   
       diaslictrat record;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_basicocat7(#,&, ?,@)
 
 -- SELECT INTO elmonto round (((monto/cantidaddiaslab)*(cantidaddiastrab * porcentajetrabajado) )::numeric,3)
 -- Calculo basico para la categoria 7
    SELECT into elmontocat  camonto
    FROM ca.categoriatipoliquidacion
    WHERE idcategoria = 7 and 	idliquidaciontipo=$2;
 
  --  Obtengo los dias laborables
     SELECT into losdiaslab  ceporcentaje
 	 FROM ca.conceptoempleado
	 WHERE idpersona = $3    and
			idconcepto = 1045  and --Dias laborables mensuales
			idliquidacion=$1;

-- Calculo dias trabajados  
	SELECT INTO diastrabajados  ceporcentaje
	FROM ca.conceptoempleado
	WHERE idpersona = $3    and idconcepto = 1084 and --Dias trabajados
	  idliquidacion=$1;
	
	
-- Calculo dias licencia
	SELECT INTO diaslicencia  ceporcentaje
	FROM ca.conceptoempleado
	WHERE idpersona = $3    and	idconcepto = 1106  and --Dias licencia
	  idliquidacion=$1;

    	
	
-- Porcentaje trabajado: vinculado a la jornada del empleado si es de 7 hrs => 100 % o menor	
    SELECT INTO porcentajetrabajado ceporcentaje
	FROM ca.conceptoempleado
	WHERE idpersona = $3    and	idconcepto = 0 and idliquidacion=$1;
			
	/* Corroboro si la persona esta con licencia por maternidad */
    SELECT INTO elidconcepto idconcepto
	FROM ca.conceptoempleado
	WHERE idpersona = $3    and	idconcepto = 1105 and idliquidacion=$1;

    IF nullvalue(elidconcepto) THEN -- notiene licencia por maternidad
          elmonto= round (((elmontocat/(losdiaslab)) *(diastrabajados + diaslicencia) * porcentajetrabajado )::numeric,5);
    ELSE  -- tiene licencia por maternidad
          elmonto= round (((elmontocat/(losdiaslab)) *(diastrabajados) * porcentajetrabajado )::numeric,5);
    END IF;


    -- Corroboro que no tenga licencia por largo tratamiento
    -- El calculo toma en cuenta los dias sin lic donde el monto varia en un 50 % a los dias con normales
          
     SELECT INTO diaslictrat SUM(ceporcentaje) as ceporcentaje
     FROM ca.conceptoempleado
     WHERE (idconcepto =1112  or idconcepto =1166 ) and idpersona = $3 and idliquidacion=$1;
     IF not nullvalue(diaslictrat.ceporcentaje) THEN
        elmonto =  (elmonto/losdiaslab) * (losdiaslab - diaslictrat.ceporcentaje ) + 0.5*( (elmonto/losdiaslab) *  diaslictrat.ceporcentaje) ;
        elmonto = round (elmonto::numeric,5);
     END IF;
 

    IF nullvalue (elmonto) THEN
        elmonto =0;
    END IF;



return elmonto ;
END;
$function$
