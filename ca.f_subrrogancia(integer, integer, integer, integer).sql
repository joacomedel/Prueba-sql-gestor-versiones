CREATE OR REPLACE FUNCTION ca.f_subrrogancia(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       diasConSup record;
       laliq record;
       catemp record;
       diaslaborables DOUBLE PRECISION;
       elmonto DOUBLE PRECISION;
       elporcentaje DOUBLE PRECISION;
       rcantdiasconsup record;
       CantDiasBasicos DOUBLE PRECISION;
       cantAniosConSup  DOUBLE PRECISION;
       cdiassuperior refcursor; 
       acumuladordiassup  DOUBLE PRECISION;
       acumuladormontosup DOUBLE PRECISION;
       cantdiasmes integer;
       categemp   date;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

/*obtengo anio y mes de la liquidacion*/
    SELECT  INTO laliq *   FROM ca.liquidacion WHERE idliquidacion=$1;

/*obtengo la categoria de subrogancia del empleado*/
SELECT  INTO categemp  cefechainicio
   FROM ca.categoriaempleado WHERE idcategoriatipo=2 and idpersona =  $3 and 
   ( nullvalue(cefechafin)  or   
  to_date(concat(laliq.lianio,'-',laliq.limes,'-1'),'YYYY-MM-DD')+ interval '1 month'- interval '1 day'<=cefechafin );




SELECT  into cantdiasmes
    DATE_PART('days', 
        DATE_TRUNC('month', NOW()) 
        + '1 MONTH'::INTERVAL 
        - DATE_TRUNC('month', NOW())
    ) as cantdiasmes;



/*obtengo el monto dela categoria de revista del empleado*/
/*saco el menor igual y dejo menor*/
    SELECT  INTO catemp *    FROM ca.categoriaempleado
			NATURAL JOIN ca.categoriatipoliquidacion
			NATURAL JOIN ca.categoriatipo
			WHERE idpersona = $3 and
			to_date(concat(laliq.lianio,'-',laliq.limes,'-1'),'YYYY-MM-DD')+ interval '1 month' > cefechainicio and (
			nullvalue(cefechafin)  or to_date(concat(laliq.lianio,'-',laliq.limes,'-1'),'YYYY-MM-DD')<=cefechafin ) 
                        and		idcategoriatipo = 1 
                        and idliquidaciontipo=$2;
				
SELECT into  diaslaborables ceporcentaje
		FROM ca.conceptoempleado
		WHERE idpersona =$3 and
		idconcepto = 1045 and
		idliquidacion=$1;

open cdiassuperior for select 
     CASE WHEN 
     (nullvalue(cefechafin) or cefechafin >=  to_timestamp(concat(lianio,'-',limes,'-1') ,
     'YYYY-MM- DD')::date+ interval '1 month' )
     THEN ((to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date+ interval 
     '1 month')::date  - cefechainicio)
     WHEN (cefechafin<= (to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date
     + interval '1 month')::date
    and cefechafin >=(to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date)
    and cefechainicio <=(to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date)
   ) THEN

   (cefechafin - to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date)+1

   ELSE
             (cefechafin - cefechainicio)+1
         END as dias,idcategoria as catsubrogancia, cefechainicio
  FROM ca.persona
  NATURAL JOIN ca.categoriaempleado
  NATURAL JOIN ca.categoriatipoliquidacion
  NATURAL JOIN ca.categoriatipo
  NATURAL JOIN ca.liquidacion
  WHERE idpersona = $3
      and idcategoriatipo = 2
      and idliquidaciontipo= $2 and idliquidacion = $1

and cefechainicio < to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month'
and  ( nullvalue(cefechafin)   or  cefechafin >= concat(lianio,'/' ,limes ,'/01')::date);
--) as d;

--Obtiene dias correspondientes al basico
  SELECT into CantDiasBasicos ceporcentaje
  FROM ca.conceptoempleado WHERE idconcepto=1084 and idliquidacion=$1 and idpersona = $3;

fetch cdiassuperior into rcantdiasconsup;
elmonto=0;
acumuladormontosup=0;
acumuladordiassup=0;
WHILE  found LOOP
         acumuladordiassup=acumuladordiassup+rcantdiasconsup.dias;
       
         --calcula la diferencia entre el monto de la categoria de revista y el monto de la categoria de --subrogancia y luego lo divide por la cantidad de dias             laborables mensuales.
        SELECT INTO elmonto round ((monto/cantidaddias)::numeric,2)
	FROM (SELECT case WHEN SUM(camonto) <-1
	THEN 0 WHEN nullvalue ( SUM(camonto))
	THEN 0 ELSE SUM(camonto) END as monto FROM ( SELECT (camonto * -1)as camonto
	FROM ca.persona NATURAL JOIN ca.categoriaempleado
			NATURAL JOIN ca.categoriatipoliquidacion
			NATURAL JOIN ca.categoriatipo
			WHERE idpersona = $3 and
				to_date(concat(laliq.lianio,'-',laliq.limes,'-1'),'YYYY-MM-DD')+ interval '1 month' > cefechainicio and (
				nullvalue(cefechafin)  or to_date(concat(laliq.lianio,'-',laliq.limes,'-1'),'YYYY-MM-DD')<=cefechafin ) and
				idcategoriatipo = 1 and
				idliquidaciontipo=$2
			UNION
				(SELECT camonto
				FROM ca.persona
				NATURAL JOIN ca.categoriaempleado
				NATURAL JOIN ca.categoriatipoliquidacion
				NATURAL JOIN ca.categoriatipo
					WHERE idpersona = $3 and to_date(concat(laliq.lianio,'-',laliq.limes,'-1'),'YYYY-MM-DD')+ interval '1 month' > cefechainicio and
					( nullvalue(cefechafin)  or   to_date(concat(EXTRACT(YEAR FROM cefechafin::timestamp) ,'-',EXTRACT(MONTH FROM cefechafin::timestamp),'-01'),'YYYY-MM-DD')<=cefechafin ) and
					idcategoriatipo = 2 
                                        and      idcategoria=rcantdiasconsup.catsubrogancia
                                        and idliquidaciontipo=$2 
                             order by     cefechafin desc /*limit 1*/))as t
				) as AUX
        NATURAL JOIN (
	SELECT ceporcentaje  as cantidaddias,idpersona
		FROM ca.conceptoempleado
		WHERE idpersona =$3 and
		idconcepto = 1045 and
		idliquidacion=$1
	) as D;

	if found then
                IF ((CantDiasBasicos < rcantdiasconsup.dias )
                  
                or  (cantdiasmes=rcantdiasconsup.dias   
    and categemp::date >= concat(laliq.lianio,'-',laliq.limes,'-','1')::date )) THEN
                        rcantdiasconsup.dias = CantDiasBasicos;
                END IF;

                acumuladormontosup=acumuladormontosup+(elmonto*rcantdiasconsup.dias);
           
	end if;
	fetch cdiassuperior into rcantdiasconsup;
end loop;
close cdiassuperior;

-- Obtengo el % de tiempo que la persona tiene asignada a su jornada
-- Se corresponde con el porcentaje del concepto Dias trabajados
   SELECT  INTO elporcentaje cemonto
   FROM ca.conceptoempleado WHERE idconcepto=998 and idliquidacion=$1 and idpersona =  $3;
-- Hay que actualizar el porcentaje con la cantidad de dias

--obtengo la cantidad de dias que tiene con categoria de subrogancia modif vas 29-05-2018

--Obtiene dias correspondientes al basico
  SELECT into CantDiasBasicos ceporcentaje
  FROM ca.conceptoempleado WHERE idconcepto=1084 and idliquidacion=$1 and idpersona = $3;

 

  IF (
  (CantDiasBasicos <  /*cantDiasConSup*/ acumuladordiassup and  acumuladordiassup<>0)
  or  (cantdiasmes=acumuladordiassup   
    and categemp::date >= concat(laliq.lianio,'-',laliq.limes,'-','1')::date )
  ) THEN
     /*cantDiasConSup*/ acumuladordiassup = CantDiasBasicos;
  END IF;
  

   UPDATE ca.conceptoempleado SET ceporcentaje =  CASE WHEN  (nullvalue(acumuladordiassup)) THEN 0 ELSE acumuladordiassup END    
   --cantDiasConSup  ---CASE WHEN  (nullvalue(cantDiasConSup)) THEN 0 ELSE cantDiasConSup END

   WHERE  idconcepto=17 and idliquidacion=$1 and idpersona = $3;

   --elmonto=elporcentaje*elmonto;
    IF (  acumuladordiassup<>0)THEN
     elmonto=acumuladormontosup/acumuladordiassup;
     elmonto=round(elmonto::numeric,3);
   ELSE
     elmonto=0;
END IF;

-- ACTUALIZO EL CONCEPTO ACA ESTO HAY QUE MODIFICARLO !!!!!!!!
  UPDATE ca.conceptoempleado SET cemonto = elmonto   --- CASE WHEN (nullvalue(elmonto)) THEN 0 ELSE  elmonto END  
   WHERE idconcepto=17 and idliquidacion=$1 and idpersona = $3;

return elmonto;
END;
$function$
