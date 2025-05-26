CREATE OR REPLACE FUNCTION ca.controldescuentos(integer, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
* Controla que una liquidacion no tenga empleados que tengan mas del 40% en descuentos o que cobren menos del sueldo minimo
*
*/
DECLARE
      codasiento integer;
      rasientotipo record;
      rasientosueldo record;
      regformula record;
      cursorasiento refcursor;
      laformula varchar;
      f varchar;
      salida boolean;


BEGIN

     SET search_path = ca, pg_catalog;
     codasiento = $1;  -- idcorrespondiente al siento creado
salida = false;

 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

 */

    OPEN cursorasiento FOR  SELECT *
           FROM ca.asientosueldoctactble
           NATURAL JOIN ca.asientosueldotipoctactble
           NATURAL JOIN ca.asientosueldo
           WHERE idasientosueldo = codasiento
           order by astorden asc;
    FETCH cursorasiento INTO rasientosueldo;
    WHILE FOUND LOOP
             -- 1- Buscar el valor de la fórmula
             SELECT INTO regformula * FROM formula WHERE idformula = rasientosueldo.idformula;
             laformula =regformula.focalculo;
             IF char_length(trim(laformula) )>0 THEN
                      laformula = reemplazarparametrosasiento(rasientosueldo.limes,rasientosueldo.lianio,rasientosueldo.idcentrocosto,rasientosueldo.nrocuentac,laformula,rasientosueldo.idasientosueldoctactble);

                      f = concat( 'UPDATE asientosueldoctactble set ascimporte =
                                      (SELECT CASE WHEN nullvalue(t.monto) THEN 0
                                              ELSE round( t.monto ::numeric, 3) END as monto
                              FROM(' , laformula , ')as t)'
                              , ' WHERE idasientosueldotipoctactble = ' , rasientosueldo.idasientosueldotipoctactble ,' and idasientosueldoctactble = ' , rasientosueldo.idasientosueldoctactble);
                     RAISE NOTICE 'FORMUlA (%)',f;
                      EXECUTE  f;
             END IF;

                     salida=true;

    FETCH cursorasiento INTO rasientosueldo;
    END LOOP;
    CLOSE cursorasiento;
              

return 	salida;
END;
$function$
