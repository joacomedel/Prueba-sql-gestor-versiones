CREATE OR REPLACE FUNCTION public.far_actualizacionlotescopahue()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

cmovimientostock refcursor;
unmovimiento record;

BEGIN
     OPEN cmovimientostock FOR SELECT *
                            FROM far_ordenventaitem
                            NATURAL JOIN far_movimientostockitem
                            WHERE idcentromovimientostockitem =14;

      FETCH cmovimientostock into unmovimiento;
      WHILE  found LOOP
             UPDATE far_lote SET idcentrolote = 14
             WHERE idlote =cmovimientostock.idlote AND idcentrolote=cmovimientostock.idcentrolote;
      
      
      FETCH cmovimientostock into unmovimiento;
      END LOOP;

return 'true';
END;
$function$
