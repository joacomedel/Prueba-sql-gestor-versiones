CREATE OR REPLACE FUNCTION public.arreglarprecioarticulo_1()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       carticulo refcursor;
       unarticulo record;
BEGIN
     -- 1 - se buscan topdos los articulos que NO tienen un valor vigente
      OPEN carticulo FOR
          SELECT *
          FROM far_articulo
          WHERE

                 (idarticulo,idcentroarticulo) NOT IN (
                     SELECT idarticulo,idcentroarticulo
                     FROM far_precioarticulo
                     WHERE nullvalue(pafechafin)

              );

     -- 2 se recorre cada uno de los medicamentos y se pone como vigente el ULTIMO VALOR encontrado
     FETCH carticulo into unarticulo;
     WHILE FOUND LOOP
           UPDATE far_precioarticulo SET pafechafin = null
           WHERE far_precioarticulo.idarticulo = unarticulo.idarticulo
                 and far_precioarticulo.idcentroarticulo = unarticulo.idcentroarticulo
                 and idprecioarticulo IN (
                     SELECT MAX (idprecioarticulo)
                     FROM far_precioarticulo
                     WHERE far_precioarticulo.idarticulo = unarticulo.idarticulo
                           and far_precioarticulo.idcentroarticulo = unarticulo.idcentroarticulo
                     group by idarticulo,idcentroarticulo

             );

            FETCH carticulo into unarticulo;
     END LOOP;
     close carticulo;
     return 'Listo';
END;
$function$
