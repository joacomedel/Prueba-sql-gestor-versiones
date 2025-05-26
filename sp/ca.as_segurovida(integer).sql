CREATE OR REPLACE FUNCTION ca.as_segurovida(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
* Inicializa el asiento correspondiente a seguro de vida (tipoasiento=1)
* PRE: el asiento debe estar creado
* 2.46 * CE
*/
DECLARE
      codasiento integer;
      rasientotipo record;
      rasientosueldo record;
      regformula record;
      
      laformula varchar;

BEGIN
   /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

     Marga y analia 14 94
     titulo antiguedad zona
  */
     SET search_path = ca, pg_catalog;
     codasiento = $1;  -- idcorrespondiente al siento creado
     SELECT INTO rasientosueldo * FROM ca.asientosueldo  WHERE idasientosueldo = codasiento;
 

    SELECT INTO rasientotipo * FROM ca.asientosueldotipoctactble WHERE idasientosueldotipo =1;
     -- 1- Buscar el valor de la fórmula
     laformula ='';
     IF not nullvalue (rasientotipo.idformula) THEN
            SELECT INTO regformula * FROM formula WHERE idformula = rasientotipo.idformula;
            laformula = regformula.focalculo;
            IF char_length(trim(laformula) )>0 THEN
                       laformula = reemplazarparametrosasiento(rasientosueldo.limes,rasientosueldo.lianio,rasientotipo.idcentrocosto,laformula);

            END IF;
      END IF ;



return 	salida;
END;
$function$
