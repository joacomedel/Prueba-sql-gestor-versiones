CREATE OR REPLACE FUNCTION ca.f_aguinaldo(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
        montototal DOUBLE PRECISION;
       valordia DOUBLE PRECISION;
       diastrabajados DOUBLE PRECISION;
       diaslicencia DOUBLE PRECISION;
       losdiaslab DOUBLE PRECISION;
       elidconcepto INTEGER;
       cantdiastrabajdosinstitucion INTEGER;
       cantdiasconmaternidad INTEGER;
       cantdiasconlsgh INTEGER;
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
--comento Dani el 16/12/2021, porpedido de JE. los dias trabajados son los dias con categorias diferentes a la de pasantia.
--Surge de calcular el aguinaldo para el legajo 179 GV, idpersona=474, idliquiidacion 754
   --SELECT INTO cantdiastrabajdosinstitucion ca.diastrabajdosinstitucion ($1, $2, $3, $4)+1;
cantdiastrabajdosinstitucion=0; 

  SELECT INTO cantdiastrabajdosinstitucion  ca.diastrabajdosinstitucionparasac ($1, $2, $3, $4)+1;
  
 RAISE NOTICE ' cantdiastrabajdosinstitucion = (%)', cantdiastrabajdosinstitucion;
if (cantdiastrabajdosinstitucion>1) then  --en realidad cantdiasparasac=0  

    SELECT INTO cantdiasconlsgh ca.diasconlsgh ($1, $2, $3, $4);
	RAISE NOTICE ' cantdiasconlsgh = (%)', cantdiasconlsgh;
	
    SELECT INTO cantdiasconmaternidad ca.diascomaternidad ($1, $2, $3, $4);
	RAISE NOTICE ' cantdiasconmaternidad = (%)', cantdiasconmaternidad;
 
    IF (cantdiastrabajdosinstitucion >=180) THEN
       cantdiastrabajdosinstitucion=180  - cantdiasconlsgh ;
    --Dani comento el 27-06-2022 pq el sp diastrabajdosinstitucionparasac ya descarta los dias con lsgh
   /* ELSE
      cantdiastrabajdosinstitucion=cantdiastrabajdosinstitucion  - cantdiasconlsgh ;*/
    END IF;
	RAISE NOTICE ' cantdiastrabajdosinstitucion = (%)', cantdiasconmaternidad;


    SELECT INTO valordia (MAX(montomax)/360)
	FROM (
         SELECT sum(leimprem - (Case WHEN nullvalue(cemonto) THEN 0 ELSE cemonto END)) as montomax,
--lifechapagoaporte
         B.limes,B.lianio
	     FROM (
    
            SELECT limes,lianio,idliquidacion,lifechapagoaporte,
                   Case WHEN idliquidaciontipo = 1 or idliquidaciontipo = 6 THEN 
--Comento Dani el 26062020 por pedido de Juli para que no sume el concepto 1134. caso Rodriguez Eduardo
-- (leimpbruto-(leimpnoremunerativo-leimpasignacionfam))
(leimpbruto-(leimpnoremunerativo-leimpasignacionfam)-(ca.conceptovalorempleado(idliquidacion,idpersona,1134,'mf')))
 

                   WHEN  idliquidaciontipo = 2 or idliquidaciontipo = 5
                   THEN (leimpbruto-leimpasignacionfam) END as leimprem
	        FROM ca.liquidacionempleado
	        NATURAL JOIN ca.liquidacion
	        WHERE idpersona=$3 and
              ( idliquidaciontipo =1 OR idliquidaciontipo=2 OR idliquidaciontipo=6 OR idliquidaciontipo=5) and
	              lianio = extract(YEAR from CURRENT_DATE)
            order by lianio DESC, limes DESC
          
       /*limit 12*/
       /*Modifico Dani 19/12/2018*/
       limit 6
    ) AS B
	LEFT  JOIN   (
          SELECT limes,lianio,idliquidacion,  SUM(cemonto*ceporcentaje )as cemonto
	      FROM ca.liquidacionempleado
	      NATURAL JOIN ca.liquidacion
	      NATURAL JOIN ca.conceptoempleado
	      WHERE idpersona=$3 and
	            --( idliquidaciontipo =1 OR idliquidaciontipo=2) and
             ( idliquidaciontipo <>3 and  idliquidaciontipo<>4) and
	              lianio = extract(YEAR from CURRENT_DATE) and
	              (idconcepto =4 or idconcepto = 33 or idconcepto = 1155 )
                      
          GROUP by idliquidacion,lianio, limes
          order by lianio DESC, limes DESC  /* limit 6*/
     )as P	USING (idliquidacion)
--GROUP by lifechapagoaporte
GROUP by B.lianio, B.limes
) as T;
    RAISE NOTICE ' valordia = (%)', valordia;
	/* Corroboro si la persona esta con licencia por maternidad  CREAR FORMULA 1105 */
    /*SELECT INTO rlicenciamaternidad SUM(ceporcentaje)as ceporcentaje
	FROM ca.conceptoempleado
    NATURAL JOIN ca.liquidacion
	WHERE idpersona = $3    and	idconcepto = 1105
          and lianio=extract(YEAR from CURRENT_DATE)
          and limes > extract(MONTH from CURRENT_DATE)-6
          and (idliquidaciontipo=1 or idliquidaciontipo=3);

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
	   */
                   --  montototal =  montototal * (cantdiastrabajdosinstitucion-diaslicencia);
               /*Comento Dani el 28-06-2019 y reempplazo por linea siguiente*/
                   /*montototal = abs( round ((cantdiastrabajdosinstitucion - rlicenciamaternidad.ceporcentaje)::numeric,3)*valordia);
*/
 RAISE NOTICE '( montototal = cantdiastrabajdosinstitucion (%) - cantdiasconmaternidad(%) )* valordia(%)', cantdiastrabajdosinstitucion,cantdiasconmaternidad,valordia;
                   montototal = abs( round ((cantdiastrabajdosinstitucion - cantdiasconmaternidad)::numeric,3)*valordia);
 RAISE NOTICE ' montototal =(%)',montototal;
                   --  montototal =cantdiastrabajdosinstitucion - rlicenciamaternidad.ceporcentaje;
                   --  montototal =  round ( ( ( montototal /abs(diastrabajados + diaslicencia) )*diastrabajados) ::numeric,5);
          
          
   /*ELSE
                   montototal  = valordia * cantdiastrabajdosinstitucion;
    END IF;
	*/
end if;--cantdiastrabajdosinstitucion>1
return montototal/0.5;
END;
$function$
