CREATE OR REPLACE FUNCTION ca.f_permanenciacategoria(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       monto DOUBLE PRECISION;
       montofinal DOUBLE PRECISION;
       elporcentaje DOUBLE PRECISION;
       diasbasico DOUBLE PRECISION;
       diastrabajados DOUBLE PRECISION;
       losdiaslab  DOUBLE PRECISION;
       diaslictrat DOUBLE PRECISION;
       reduccional50  DOUBLE PRECISION;
       elidconcepto INTEGER;
       datoliq record;
       auxporcentaje  DOUBLE PRECISION;
       priorsup INTEGER;
       regcategoria record;
       camontosuperior DOUBLE PRECISION;
       rconf_jornada record;


BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_permanenciacategoria(#,&, ?,@)
    elporcentaje = 0;

reduccional50  =1;
 ---- 1 Calculo la categoria actual del empleado
SELECT INTO datoliq * FROM ca.liquidacion WHERE idliquidacion = $1;
  
-- Dani modifico 22032024   EXTRACT(YEAR FROM age(cefechapermanencia)) as aniopermanencia
-- SELECT INTO regcategoria caprioridad,camonto,EXTRACT(YEAR FROM age(cefechapermanencia)) as aniopermanencia
 
SELECT INTO regcategoria caprioridad,camonto,


EXTRACT(YEAR FROM age( to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1')  ,'YYYY-MM-DD')+ interval '1 month' - interval '1 day',cefechapermanencia ))as aniopermanencia

 FROM ca.categoria
    NATURAL JOIN ca.categoriatipoliquidacion
    NATURAL JOIN ca.categoriaempleado
    NATURAL JOIN ca.categoriatipo
    WHERE idpersona = $3
        and idliquidaciontipo=$2
    -- Dani modifico 22032024   EXTRACT(YEAR FROM age(cefechapermanencia)) as aniopermanencia
    --  and CURRENT_DATE >= cefechainicio
       and to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date >= cefechainicio
       and   (nullvalue(cefechafin) or cefechafin >=to_timestamp(concat(datoliq.lianio,'-',datoliq.limes,'-1') ,'YYYY-MM-DD')::date)
 





        and   idcategoriatipo = 1;
	
	raise notice 'lo que tiene datoliq (%)',regcategoria;
        
-- Busco la categoria superior
    IF regcategoria.caprioridad <> 1 THEN
      priorsup = regcategoria.caprioridad - 1;
    ELSE
       priorsup = 1;
    END IF;
 -- Calculo el monto basico de la categoia superior
    SELECT INTO camontosuperior camonto
    FROM ca.categoria
    NATURAL JOIN ca.categoriatipoliquidacion
    WHERE idliquidaciontipo=$2
           and caprioridad =  priorsup;
 
    -- calculo la diferencia entre las 2 categorias
    monto = camontosuperior - regcategoria.camonto;
 
    --  Obtengo los dias laborables
    SELECT INTO losdiaslab  ceporcentaje
 	FROM ca.conceptoempleado
    WHERE idpersona = $3    and
	 	   idconcepto = 1045  and --Dias laborables mensuales
		   idliquidacion=$1;

    SELECT INTO diasbasico   ceporcentaje
    FROM ca.conceptoempleado
	WHERE idpersona = $3    and idconcepto = 1084 and --Dias correspondiente al basico
	     idliquidacion=$1;
    montofinal = monto *  (diasbasico / losdiaslab) ;

    -- Corroboro que la persona tenga licencia por largo tratamiento, en ese caso corresponde un 0.5
    SELECT INTO diaslictrat SUM(ceporcentaje) as ceporcentaje
    FROM ca.conceptoempleado
    WHERE (idconcepto =1112 or idconcepto =1166 )and idpersona = $3 and idliquidacion=$1;
    IF FOUND AND not nullvalue(diaslictrat) THEN
       montofinal = montofinal + 0.5 *(monto *  (diaslictrat / losdiaslab) );
    
    END IF;
    
    -- Corroboro si la persona esta con licencia por maternidad
    SELECT INTO elidconcepto idconcepto
	FROM ca.conceptoempleado
	WHERE idpersona = $3    and	idconcepto = 1105 and idliquidacion=$1;

    IF NOT nullvalue(elidconcepto) THEN -- tiene licencia por maternidad
          -- Recupero la cantidad de dias sin tener en cuenta la licencia por maternidad
          -- Calculo dias licencia
          SELECT INTO diastrabajados  ceporcentaje
          FROM ca.conceptoempleado
	  WHERE idpersona = $3    and	idconcepto = 1106  and --Dias licencia
                idliquidacion=$1;
          montofinal =  round ( ( ( monto /abs(diastrabajados + diasbasico) )*diasbasico) ::numeric,5);
         
    END IF;
--Dani 26012022 agrego para que devuelva el 50% en el caso de reduccion de sueldo. Caso leg 17, Liq Enero2022

 SELECT INTO reduccional50 ceporcentaje
		FROM ca.conceptoempleado
 		WHERE  idpersona  = $3 and
		idconcepto = 0 and
		idliquidacion=$1;	

       		
	    
   SELECT INTO rconf_jornada * FROM ca.conceptoempleado WHERE  idliquidacion  = $1 and idpersona  = $3 and idconcepto = 100;
    -- Calcular el monto final teniendo en cuenta jornada reducida
   IF(rconf_jornada.cemonto <> rconf_jornada.ceporcentaje and diasbasico<>0 and rconf_jornada.ceporcentaje<>0) THEN
              montofinal = round (( ((montofinal / diasbasico)/rconf_jornada.ceporcentaje) * rconf_jornada.cemonto *diasbasico ) ::numeric,5); 
   END IF;

--Dani 26012022 agrego para que devuelva el 50% en el caso de reduccion de sueldo. Caso leg 17, Liq Enero2022

montofinal = montofinal * reduccional50 ;

    ----- Calculo el porcentaje que corresponde liquidar segun los años de antiguedad
    IF not nullvalue(regcategoria.aniopermanencia ) THEN

            IF(regcategoria.aniopermanencia >=2 and  regcategoria.aniopermanencia<4) THEN
                  elporcentaje = 0.1;
            END IF;
            IF(regcategoria.aniopermanencia >=4 and  regcategoria.aniopermanencia<6) THEN
                  elporcentaje = 0.25;
            END IF;
            IF(regcategoria.aniopermanencia >=6 and  regcategoria.aniopermanencia<8) THEN
                  elporcentaje = 0.45;
            END IF;
            IF(regcategoria.aniopermanencia >=8 ) THEN
                  elporcentaje = 0.7;
            END IF;

           
      raise notice 'lo que tiene elporcentaje (%)',elporcentaje;

      END IF;
       -- Actualizo los datos del concepto
       UPDATE ca.conceptoempleado SET ceporcentaje = elporcentaje , cemonto = montofinal
       WHERE idliquidacion  = $1    and idpersona  = $3  and idconcepto = 10;
     
    select  into auxporcentaje ceporcentaje from  ca.conceptoempleado 
       WHERE idliquidacion  = $1    and idpersona  = $3  and idconcepto = 10;
       raise notice 'lo que tiene auxporcentaje (%)',auxporcentaje;
     
       

 return  montofinal;
END;
$function$
