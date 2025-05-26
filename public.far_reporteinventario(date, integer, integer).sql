CREATE OR REPLACE FUNCTION public.far_reporteinventario(date, integer, integer)
 RETURNS SETOF far_inventario
 LANGUAGE plpgsql
AS $function$
DECLARE
       fechainventario date;
       rinventario far_inventario;
       elidcentro integer;
       elidrubro integer;
BEGIN
     fechainventario = $1;
      elidcentro = $2;
      elidrubro = $3;
for rinventario in
     SELECT  adescripcion,acodigobarra,rdescripcion , msistockposterior as cantidad ,
            far_precioventafecha(idarticulo ,idcentroarticulo,fechainventario::date ) as unitario,
            far_precioventafecha(idarticulo ,idcentroarticulo,fechainventario::date )  * msistockposterior  as total

      FROM far_lote
      NATURAL JOIN (
              SELECT idlote,idcentrolote , MAX(idmovimientostock)as idmovimientostock ,1 as idcentromovimientostock
              FROm far_movimientostockitem
              NATURAL JOIN far_movimientostock
              WHERE msfecha::date <= fechainventario
                    and idcentromovimientostock = 1
              group by idlote,idcentrolote ) as T
      NATURAL JOIN far_articulo
      NATURAL JOIN far_rubro
      NATURAL JOIN far_movimientostockitem
      NATURAL JOIN far_movimientostock
      WHERE idcentroarticulo =1





loop
return next rinventario;
end loop;


END;
$function$
