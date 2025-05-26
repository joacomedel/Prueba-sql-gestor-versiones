CREATE OR REPLACE FUNCTION ca.amempleado()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elidpersona INTEGER;
       lafecha date;
       aniosaniguedad INTEGER;
       elidliquidacion integer;
        rliquidacion record;
BEGIN
elidpersona = $1;
lafecha = $2;
elidliquidacion = $3;
SELECT INTO rliquidacion * FROM ca.liquidacion WHERE idliquidacion = elidliquidacion;
/* calcula antiguedad de un empleado de SOSUNC:
la antiguedad se calcula como la cantidad de años al 32/12 del año a liquidar*/
IF(rliquidacion.idliquidaciontipo = 1 or rliquidacion.idliquidaciontipo = 3 ) THEN

		SELECT INTO aniosaniguedad  CASE  WHEN extract(YEAR from age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),
               emfechainicioantiguedad)) >=1
                        THEN extract(YEAR FROM age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),
         		emfechainicioantiguedad) )+1

      	      WHEN ( extract(YEAR from age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),
              emfechainicioantiguedad)) =0 and  extract(MONTH from age( to_timestamp(concat(EXTRACT(YEAR FROM lafecha)-1 ,'-12','-31'),'YYYY-MM-DD'),emfechainicioantiguedad)) >= 6  )
         THEN 1
         ELSE 0
         END as anios 
		FROM ca.empleado
		WHERE idpersona = elidpersona;
ELSE
/* calcula antiguedad de un empleado de FARMACIA: 
la antiguedad laboral se calcula como la cantidad de años desde su ingreso a la institucion*/        

    SELECT INTO  aniosaniguedad extract(YEAR 
								from age(to_timestamp(concat(rliquidacion.lianio ,'-',rliquidacion.limes,'-31'),'YYYY-MM-DD'),
                                 emfechainicioantiguedad))
     FROM ca.empleado
     WHERE idpersona = elidpersona;
    
    

END IF;

return true;
END;$function$
