CREATE OR REPLACE FUNCTION ca.f_valorhora(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       candiaslaborables  DOUBLE PRECISION;
       canhorasd  DOUBLE PRECISION;
       candiasdiasbasico DOUBLE PRECISION;
       candiasnoremunerativos DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_bruto(#,&, ?,@)

--Calcula el valor de la hora
/*
Este fue el ultimo cambio de la fromula
SELECT INTO elmonto CASE WHEN nullvalue( SUM(cemonto*ceporcentaje)) THEN 0
       ELSE SUM(cemonto*ceporcentaje) END
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3 and
	      (idconceptotipo= 1 -- adicional
              or idconceptotipo=5 -- basico
             or idconceptotipo =2 -- suplemento
              or idconcepto = 1105 --	Bruto para Licencia por Maternidad
           )
            -- and idconcepto <>     1155 -- Ajuste Suplemento Premio
           -- and idconcepto <> 1139  --ajuste basico
            and codescripcion not ilike '%ajuste%' -- 17/12/13 se excluye todos los ajuste  

            and idconcepto <>4  -- asignaciones familiares
            and idliquidacion= $1; 
*/

/*Suma los conceptos de tipo  adicional,basicos, suplementos,Licencia Vacaciones Anuales y deja afuera  
Ajuste Suplemento Premio, Ajuste  Basico,se excluye todos los ajuste, premio,
 Horas Extras  50%
*/
SELECT INTO elmonto CASE WHEN nullvalue( SUM(cemonto*ceporcentaje)) THEN 0
       ELSE SUM(cemonto*ceporcentaje) END
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3 and
	      (idconceptotipo= 1 -- adicional
           or idconceptotipo=5 -- basico
           or idconceptotipo =2 --suplementos
         --  or (idconceptotipo =12 and idconcepto = 1105)  -- Agrego Vivi 23-01-2014 para que tome el importe no remunerativo
          
           or idconcepto =1046 --Agrego Dani 28012014 : Licencia Vacaciones Anuales

 )
             and idconcepto <>     1155 -- Ajuste Suplemento Premio
             and idconcepto <>     1139 -- Ajuste  Basico
 and codescripcion not ilike '%ajuste%' -- 17/12/13 se excluye todos los ajuste  
            and idconcepto <>4  -- premio
  and idconcepto <>996 -- para que no tengo en cuenta el concepto Horas Extras  50%

            and idliquidacion= $1;
-- Estos 140 ? no depende de la cantidad de horas que tiene la persona asignada a la jornada???

--calcula la cantidad de dias correspondientes al basico
SELECT into candiaslaborables ceunidad
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3
	       and idconcepto =1084  --Dias corresponde Basico
           and idliquidacion=$1;
           
--calcula la cantidad de dias laborables mensuales
SELECT into candiasdiasbasico ceunidad
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3
	       and idconcepto =1045 --Dias laborables mensuales
           and idliquidacion=$1;

--calcula la cantidad de dias no remunerativos
SELECT into candiasnoremunerativos ceunidad
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3
	       and idconcepto =1105 --Bruto para Licencia por Maternidad
           and idliquidacion=$1;




--calcula la cantidad de horas asignadas a la jornada
--28-05-2012 Modifica Malapi para que se devuelva la cantidad de horas semanales de la Jornada
/*SELECT into canhorasd CASE WHEN idconcepto = 100 THEN ceporcentaje*5
    WHEN idconcepto = 1136 THEN ceporcentaje
    ELSE  0
    END as ceporcentaje
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3
       and   (idconcepto =100  --Cantidad de horas de la Jornada diaria en sosunc
       				OR idconcepto = 1136 --Cantidad de horas de la jornada semanal en la farmacia
                    )
       and idliquidacion=$1;*/
--

SELECT into canhorasd CASE WHEN idconcepto = 100 THEN ceporcentaje
    WHEN idconcepto = 1136 THEN ceporcentaje
    ELSE  0
    END as ceporcentaje
	FROM ca.conceptoempleado
	NATURAL JOIN ca.concepto
	NATURAL JOIN ca.liquidacion
	WHERE idpersona= $3
       and   (idconcepto =100  --Cantidad de horas de la Jornada diaria en sosunc
       				OR idconcepto = 1136 --Cantidad de horas de la jornada semanal en la farmacia
                    )
       and idliquidacion=$1;
   
-- Comento esto  (elmonto /(canhorasd*5*4)); y lo cambio a esto  (elmonto /(canhorasd*4));
  if($2 = 1 or $2 =6) then -- si la liquidacion es sueldo sosunc
         IF nullvalue (candiasnoremunerativos ) THEN candiasnoremunerativos = 0; END IF;
         IF candiaslaborables =0 and candiasnoremunerativos <> 0  THEN
                  elmonto =  (elmonto / candiasnoremunerativos ) * (candiasdiasbasico);
         ELSE
              IF candiaslaborables <> 0 THEN
                   elmonto =  (elmonto / candiaslaborables ) * (candiasdiasbasico);
              END IF;
         END IF;
         
        if (canhorasd<>0) then  elmonto = elmonto /(canhorasd*5*4);
        else elmonto=0;
          end if;
   ELSE
if (canhorasd<>0) then  elmonto = elmonto /(canhorasd*4);
        else elmonto=0;       
   end if;
   END IF;

  
return elmonto;

END;
$function$
