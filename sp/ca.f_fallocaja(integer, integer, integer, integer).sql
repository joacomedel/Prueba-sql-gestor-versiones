CREATE OR REPLACE FUNCTION ca.f_fallocaja(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       valordiabasico DOUBLE PRECISION;
       diasmensuales integer;
       diasnotrabajados  integer;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

     --f_funcion(#,&, ?,@)
     -- calculo los dias laborables mensuales
     SELECT INTO diasmensuales ceporcentaje
     FROM ca.conceptoempleado
     WHERE  idconcepto = 1045 and idpersona = $3  and idliquidacion= $1;

    -- calculo la cantidad de dias NO trabajados
     SELECT INTO diasnotrabajados ceporcentaje
     FROM ca.conceptoempleado
     WHERE idconcepto = 1121 and  idpersona = $3   and idliquidacion= $1;

    
    --  obtengo el importe del basico
     SELECT INTO valordiabasico cemonto
     FROM ca.conceptoempleado
     WHERE idconcepto = 1044 and  idpersona = $3    and idliquidacion= $1;

     -- obtengo el importe correspondiente a los dias que corresponde fallo de caja
     elmonto = (diasmensuales - diasnotrabajados ) * valordiabasico ;
     if nullvalue(elmonto) THEN elmonto =0; END IF;

 return elmonto;
END;
$function$
