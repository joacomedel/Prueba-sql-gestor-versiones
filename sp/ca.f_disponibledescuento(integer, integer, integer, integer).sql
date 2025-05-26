CREATE OR REPLACE FUNCTION ca.f_disponibledescuento(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       candiaslaborables  DOUBLE PRECISION;
       canhorasd  DOUBLE PRECISION;
       candiasdiasbasico DOUBLE PRECISION;
       candiasnoremunerativos DOUBLE PRECISION;
       rmontos RECORD;
BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
  /*   codliquidacion = $1 ;
     eltipo = $2 ;
     idpersona =  $3 ;
     idconcepto = $4;
     laformula = $5;
*/
--f_bruto(#,&, ?,@)

    elmonto=0;
    
   
    
    SELECT INTO rmontos ca.f_bruto($1,$2,t.idpersona,123) as bruto,
                 ca.f_descuentoley($1,$2,t.idpersona,123) as descuentoley,
                 ca.f_descuentoafil($1,$2,t.idpersona,123) as descuentoafil,
                 ca.f_descuentosadicionales($1,$2,t.idpersona,123) as descuentoadic ;
             

    SELECT INTO elmonto (montos.bruto-montos.descuentoley-montos.descuentoafil-montos.descuentoadic);

    IF nullvalue(elmonto) THEN elmonto =0; END IF; 

    return elmonto;

END;
$function$
