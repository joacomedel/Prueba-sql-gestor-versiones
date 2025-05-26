CREATE OR REPLACE FUNCTION ca.as_sumaasientos(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento 
* PRE: el asiento debe estar creado
* 
*/
DECLARE
      valor  double precision ;
      elmes integer;
      elanio integer;
      laformula varchar;
      respuesta record;
      elidasientosueldotipo integer;
      

BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;
     elanio=$2;
     elidasientosueldotipo=$3;
     valor=0;

 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */


    SELECT  INTO valor 
    round(sum(ascimporte)::numeric,2)   as calculo
    FROM ca.asientosueldo
    NATURAL JOIN ca.asientosueldoctactble
    NATURAL JOIN ca.asientosueldotipoctactble
    WHERE limes =elmes 
           and lianio =elanio  
           and idasientosueldotipo=elidasientosueldotipo
           and  not(ascactivo) and asvigente;



return valor;


END;
$function$
