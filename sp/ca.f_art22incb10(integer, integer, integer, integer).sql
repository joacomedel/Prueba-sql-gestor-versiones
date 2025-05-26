CREATE OR REPLACE FUNCTION ca.f_art22incb10(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       elbasico DOUBLE PRECISION;
       montoantiguedad DOUBLE PRECISION;
       datomonto record;
       datoporcentaje record;
       rconcepto record;
       rliquidacion record;
       proporcion DOUBLE PRECISION;


BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_antiguedad(#,&, ?,@)
elmonto=0;
montoantiguedad=0;


SELECT INTO rliquidacion *
    FROM ca.liquidacion 
    WHERE 
 idliquidacion= $1;

/* Segun MAil de Julieta E. del dia 26052020(básico de Cadete - Aprendiz Ayudante + Escalafón antigüedad) x 20%.*/

	SELECT  into elmonto 
	camonto
	from  ca.categoriatipoliquidacion
	where   
		idcategoria = 12      and
		idliquidaciontipo=2   ;  

   SELECT  into montoantiguedad
	 ceporcentaje*cemonto  
	from  ca.conceptoempleado
	where   
		idpersona = $3      and
		idliquidacion=$1 and idconcepto=1050 ;

  
if not (found)or nullvalue(montoantiguedad) then montoantiguedad=0;
end if;
     
      
return elmonto+montoantiguedad;
END;
$function$
