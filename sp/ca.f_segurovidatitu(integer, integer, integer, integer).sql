CREATE OR REPLACE FUNCTION ca.f_segurovidatitu(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
              monto DOUBLE PRECISION;
       montojubyley DOUBLE PRECISION;
       elmontofinal DOUBLE PRECISION;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
/*codliquidacion = $1 # ;
     eltipo = $2 &;
     idpersona =  $3 ?;
     idconcepto = $4;
     laformula = $5;*/

--f_aguinaldo(#,&, ?,@)


        SELECT INTO monto CASE WHEN nullvalue(sum(ceporcentaje * cemonto)) THEN 0
        ELSE sum(ceporcentaje * cemonto) END as mont
        FROM ca.conceptoempleado
        NATURAL JOIN ca.concepto
        WHERE (idpersona =$3 and idliquidacion =$1 and idconcepto <> 996
        and (idconceptotipo=5 or idconceptotipo=1 or idconceptotipo=7 or idconceptotipo=2 ));

        SELECT INTO montojubyley CASE WHEN nullvalue(sum(ceporcentaje * cemonto)) THEN 0
                      ELSE sum(ceporcentaje * cemonto) END
        FROM ca.conceptoempleado
        NATURAL JOIN ca.concepto
        WHERE  (idconcepto = 201
            or idconcepto = 201
            or idconcepto = 202)
            and idpersona =$3  and idliquidacion =$1 ;

       monto = monto - montojubyley;
       IF (monto<=3750) THEN
         monto =3750;
       END IF;
       IF ( monto>=7500) THEN
         monto = 7500;
       END IF;

      elmontofinal = (monto*20)*0.00089;



return elmontofinal;
END;
$function$
