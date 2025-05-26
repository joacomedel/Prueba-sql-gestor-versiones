CREATE OR REPLACE FUNCTION public.far_corregircopahuearticulo()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       seq_far_articulo  bigint;
nada bigint;
       indice   bigint;

       cfar_articulo refcursor;
       rfar_articulo record;

       cfar_articulo_copahue refcursor;
       rfar_articulo_copahue record;

BEGIN

     ----------- Actualizo los idafiliados que sondiferentes en public y en copahue
     --- prevalece idafiliado de public

     OPEN cfar_articulo FOR SELECT  public.far_articulo.*
                                    ,copahue.far_articulo.idarticulo as idmodifica
                                    ,copahue.far_articulo.idcentroarticulo as idmodificacentro
          FROM copahue.far_articulo
          JOIN public.far_articulo using (acodigobarra)
          WHERE not (copahue.far_articulo.idarticulo = public.far_articulo.idarticulo
                      and copahue.far_articulo.idcentroarticulo= public.far_articulo.idcentroarticulo
          );

      FETCH cfar_articulo INTO rfar_articulo;
      WHILE  found LOOP
              UPDATE copahue.far_articulo
                     SET  idarticulo = rfar_articulo.idarticulo,
                          idcentroarticulo = rfar_articulo.idcentroarticulo,
                          acodigointerno =  rfar_articulo.idarticulo *100000
                     WHERE  copahue.far_articulo.idarticulo =rfar_articulo.idmodifica
                            and copahue.far_articulo.idcentroarticulo =rfar_articulo.idmodificacentro ;
              

             UPDATE copahue.far_medicamento
                    SET idarticulo = rfar_articulo.idarticulo,
                        idcentroarticulo =rfar_articulo.idcentroarticulo
                    WHERE  copahue.far_medicamento.idarticulo =rfar_articulo.idmodifica
                           and copahue.far_medicamento.idcentroarticulo =rfar_articulo.idmodificacentro ;

            UPDATE copahue.far_ordenventaitem 
                   SET idarticulo = rfar_articulo.idarticulo,
                       idcentroarticulo = rfar_articulo.idcentroarticulo
                   WHERE  copahue.far_ordenventaitem.idarticulo =rfar_articulo.idmodifica
                          and copahue.far_ordenventaitem.idcentroarticulo =rfar_articulo.idmodificacentro ;

            UPDATE copahue.far_precioarticulo 
                   SET idarticulo = rfar_articulo.idarticulo,
                        idcentroarticulo = rfar_articulo.idcentroarticulo
                   WHERE  copahue.far_precioarticulo.idarticulo =rfar_articulo.idmodifica
                          and copahue.far_precioarticulo.idcentroarticulo =rfar_articulo.idmodificacentro ;

--
  	    UPDATE copahue.far_pedidoitems 
                   SET idarticulo = rfar_articulo.idarticulo,
                        idcentroarticulo = rfar_articulo.idcentroarticulo
                   WHERE  copahue.far_pedidoitems.idarticulo =rfar_articulo.idmodifica
                          and copahue.far_pedidoitems.idcentroarticulo =rfar_articulo.idmodificacentro ;

            UPDATE copahue.far_precargarpedido 
                   SET idarticulo = rfar_articulo.idarticulo,
                        idcentroarticulo = rfar_articulo.idcentroarticulo
                   WHERE  copahue.far_precargarpedido.idarticulo =rfar_articulo.idmodifica
                          and copahue.far_precargarpedido.idcentroarticulo =rfar_articulo.idmodificacentro ;



                          

              UPDATE copahue.far_lote SET idarticulo  = rfar_articulo.idarticulo,
                                  idcentroarticulo = rfar_articulo.idcentroarticulo
              WHERE  copahue.far_lote.idarticulo =rfar_articulo.idmodifica
                          and copahue.far_lote.idcentroarticulo =rfar_articulo.idmodificacentro ;


              FETCH cfar_articulo into rfar_articulo;
      END LOOP;
      close cfar_articulo;


     -- Obtener el valor de la secuencia de far_afiliado en public
     SELECT INTO seq_far_articulo nextval('far_articulo_idarticulo_seq');

     indice = seq_far_articulo;
     /* buesco si hay articulos en copahue que NO estan  en nqn*/
     OPEN cfar_articulo_copahue FOR
                            SELECT  copahue.far_articulo.*
                            FROM copahue.far_articulo
                            LEFT JOIN public.far_articulo using (acodigobarra)
                            WHERE  nullvalue( public.far_articulo.acodigobarra)
                                   and copahue.far_articulo.idcentroarticulo = 14;


     FETCH cfar_articulo_copahue into rfar_articulo_copahue;
     WHILE  found LOOP

        
            UPDATE copahue.far_articulo
                   SET idarticulo  = indice,
                        acodigointerno = indice *100000,
                        idcentroarticulo = 1
            WHERE  copahue.far_articulo.idarticulo =rfar_articulo_copahue.idarticulo
                   and copahue.far_articulo.idcentroarticulo = 14;
            
            
            UPDATE copahue.far_medicamento SET 
                   idarticulo  = indice,
                   idcentroarticulo = 1
            WHERE  copahue.far_medicamento.idarticulo =rfar_articulo_copahue.idarticulo
                   and copahue.far_medicamento.idcentroarticulo = 14;

            UPDATE copahue.far_ordenventaitem SET idarticulo  = indice,                        idcentroarticulo = 1
            WHERE  copahue.far_ordenventaitem.idarticulo =rfar_articulo_copahue.idarticulo
                   and copahue.far_ordenventaitem.idcentroarticulo = 14;

            UPDATE copahue.far_precioarticulo 
                  SET idarticulo  = indice,   
                     idcentroarticulo = 1
            WHERE  copahue.far_precioarticulo.idarticulo =rfar_articulo_copahue.idarticulo
                   and copahue.far_precioarticulo.idcentroarticulo = 14;
----


            UPDATE copahue.far_pedidoitems 
                   SET idarticulo = indice,
                        idcentroarticulo = 1
                   WHERE  copahue.far_pedidoitems.idarticulo =rfar_articulo_copahue.idarticulo
                          and copahue.far_pedidoitems.idcentroarticulo =14 ;

            UPDATE copahue.far_precargarpedido 
                   SET idarticulo =indice,
                        idcentroarticulo = 1
                   WHERE  copahue.far_precargarpedido.idarticulo =rfar_articulo_copahue.idarticulo
                          and copahue.far_precargarpedido.idcentroarticulo = 14;


----

                   
/*
            UPDATE copahue.far_lote SET idarticulo  =indice,
                                  idcentroarticulo = 1
            WHERE  copahue.far_lote.idarticulo =rfar_articulo_copahue.idarticulo
                          and copahue.far_lote.idcentroarticulo =14 ;
            */
             indice = indice +1 ;
             FETCH cfar_articulo_copahue into rfar_articulo_copahue;
      END LOOP;

      close cfar_articulo_copahue;

      SELECT INTO nada setval('far_articulo_idarticulo_seq', indice-1);
      -- actualizar el valor de la secuencia con el valor que quedo la variable contador;



return 'true';
END;
$function$
