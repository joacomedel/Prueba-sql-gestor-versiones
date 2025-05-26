CREATE OR REPLACE FUNCTION ca.f_farmaguinaldo(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       valordia DOUBLE PRECISION;
        cantdiastrabajdosinstitucion INTEGER;
        montototal DOUBLE PRECISION;
        rlicenciamaternidad record;
       diastrabajados DOUBLE PRECISION;
       diaslicencia DOUBLE PRECISION;
       losdiaslab DOUBLE PRECISION;
       cantdiasconmaternidad INTEGER;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_farmaguinaldo(#,&, ?,@)
cantdiasconmaternidad=0;

SELECT INTO cantdiastrabajdosinstitucion ca.diastrabajdosinstitucion ($1, $2, $3, $4)+1;
 --SELECT INTO cantdiasconmaternidad ca.diascomaternidad ($1, $2, $3, $4)+1;
 SELECT   INTO cantdiasconmaternidad  case when  ca.diascomaternidad ($1, $2, $3, $4)=0  then 0 else  1+ca.diascomaternidad ($1, $2, $3, $4) end ;


IF (cantdiastrabajdosinstitucion >=180) THEN
   cantdiastrabajdosinstitucion=180;
END IF;
 

SELECT INTO valordia  MAX(monto)/360
	FROM ( SELECT SUM(ceporcentaje * cemonto)as monto,idliquidacion 
		FROM ca.conceptoempleado 
	    NATURAL JOIN ca.liquidacion
	    WHERE idpersona=$3 and 
		    (idconcepto=1028 or idconcepto=1050 or idconcepto=1048
              or idconcepto =1133  or idconcepto=996 or idconcepto =1085
              or idconcepto =1142
              or idconcepto=1159 or idconcepto =1156
              or idconcepto=1157 or idconcepto=1080
              or idconcepto=1151 or idconcepto=1152
              or idconcepto=1158 or idconcepto=1046
              or idconcepto=1145
              or idconcepto=1192
              or idconcepto=1181 or idconcepto=1182
              or idconcepto=1207
              or idconcepto=1224
              or idconcepto=1225
              or idconcepto=1228
              or idconcepto=1230
/*Dani agrego por pedido de Julieta E el27-06-2019*/

              or idconcepto=1239
              or idconcepto=1240
              or idconcepto=1229
              or idconcepto=1139 ---(13:18:27) Julieta Esteves (int. 50): y no toma el concepto 1139 ajuste basico
              or idconcepto=1254 --Agrego Dani el 25062020 porpedido de Julieta E.
             
              or idconcepto=1282
              or idconcepto=1274 --falta injustificada  se agrega por pedio de JE segun chat 25062024

    ) and
	idliquidaciontipo=2
    group by idliquidacion
    ORDER by idliquidacion DESC
  limit 6) as T;
        
--Malapi Agrego para que soporte la licencia por maternidad en farmacia. Tomo como base la formula de sosunc

/* Corroboro si la persona esta con licencia por maternidad  CREAR FORMULA 1105 */
/*    SELECT INTO rlicenciamaternidad SUM(ceporcentaje)as ceporcentaje
	FROM ca.conceptoempleado
    NATURAL JOIN ca.liquidacion
	WHERE idpersona = $3    and	idconcepto = 1105
          and lianio=extract(YEAR from CURRENT_DATE)
          and limes > extract(MONTH from CURRENT_DATE)-6;

    IF NOT nullvalue(rlicenciamaternidad.ceporcentaje) THEN -- tiene licencia por maternidad
                 SELECT INTO diastrabajados   ceporcentaje
	             FROM ca.conceptoempleado
	             WHERE idpersona = $3    and idconcepto = 998 and --Dias trabajados
	                   idliquidacion=$1;
	
                --  Obtengo los dias laborables
                SELECT into losdiaslab  ceporcentaje
 	            FROM ca.conceptoempleado
	            WHERE idpersona = $3    and
			          idconcepto = 1045  and --Dias laborables mensuales
			          idliquidacion=$1;
	*/
      
                   
                   montototal =  round ((cantdiastrabajdosinstitucion /*- rlicenciamaternidad.ceporcentaje*/-cantdiasconmaternidad)::numeric,3)*valordia;

                  
          
          
   
                   montototal  = valordia * round ((cantdiastrabajdosinstitucion-cantdiasconmaternidad)::numeric,3);
------ cambiar por SELECT  elmonto = (elmonto/30)* ca.diastrabajdosinstitucion (305,3, 305, 4)+1
   -- END IF;
	




return montototal /0.5;
END;



/*
SELECT ((MAX(monto)/6) * count(*)) as monto  FROM ( SELECT SUM(ceporcentaje * cemonto)as monto,idliquidacion FROM ca.conceptoempleado NATURAL JOIN ca.liquidacion WHERE idpersona=? and (idconcepto=1028 or idconcepto=1050 or idconcepto=1048) and  idliquidaciontipo=2 group by idliquidacion  ORDER by idliquidacion DESC  ) as T
*/
$function$
