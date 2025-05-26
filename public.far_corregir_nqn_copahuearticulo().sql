CREATE OR REPLACE FUNCTION public.far_corregir_nqn_copahuearticulo()
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

          OPEN cfar_articulo FOR SELECT  neuquen.far_articulo.*
                                    ,public.far_articulo.idarticulo as idmodifica
                                    ,public.far_articulo.idcentroarticulo as idmodificacentro
          FROM neuquen.far_articulo
          JOIN public.far_articulo using (acodigobarra)
          WHERE not (neuquen.far_articulo.idarticulo = public.far_articulo.idarticulo
                      and neuquen.far_articulo.idcentroarticulo= public.far_articulo.idcentroarticulo
          );

      FETCH cfar_articulo INTO rfar_articulo;
      WHILE  found LOOP
              UPDATE public.far_articulo
                     SET  idarticulo = rfar_articulo.idarticulo,
                          idcentroarticulo = rfar_articulo.idcentroarticulo,
                          acodigointerno =  rfar_articulo.idarticulo *100000
                     WHERE  public.far_articulo.idarticulo =rfar_articulo.idmodifica
                            and public.far_articulo.idcentroarticulo =rfar_articulo.idmodificacentro ;
              

             UPDATE public.far_medicamento
                    SET idarticulo = rfar_articulo.idarticulo,
                        idcentroarticulo =rfar_articulo.idcentroarticulo
                    WHERE  public.far_medicamento.idarticulo =rfar_articulo.idmodifica
                           and public.far_medicamento.idcentroarticulo =rfar_articulo.idmodificacentro ;

            UPDATE public.far_ordenventaitem 
                   SET idarticulo = rfar_articulo.idarticulo,
                       idcentroarticulo = rfar_articulo.idcentroarticulo
                   WHERE  public.far_ordenventaitem.idarticulo =rfar_articulo.idmodifica
                          and public.far_ordenventaitem.idcentroarticulo =rfar_articulo.idmodificacentro ;

            UPDATE public.far_precioarticulo 
                   SET idarticulo = rfar_articulo.idarticulo,
                        idcentroarticulo = rfar_articulo.idcentroarticulo
                   WHERE  public.far_precioarticulo.idarticulo =rfar_articulo.idmodifica
                          and public.far_precioarticulo.idcentroarticulo =rfar_articulo.idmodificacentro ;

--
  	    UPDATE public.far_pedidoitems 
                   SET idarticulo = rfar_articulo.idarticulo,
                        idcentroarticulo = rfar_articulo.idcentroarticulo
                   WHERE  public.far_pedidoitems.idarticulo =rfar_articulo.idmodifica
                          and public.far_pedidoitems.idcentroarticulo =rfar_articulo.idmodificacentro ;

            UPDATE public.far_precargarpedido 
                   SET idarticulo = rfar_articulo.idarticulo,
                        idcentroarticulo = rfar_articulo.idcentroarticulo
                   WHERE  public.far_precargarpedido.idarticulo =rfar_articulo.idmodifica
                          and public.far_precargarpedido.idcentroarticulo =rfar_articulo.idmodificacentro ;



                          

              UPDATE public.far_lote SET idarticulo  = rfar_articulo.idarticulo,
                                  idcentroarticulo = rfar_articulo.idcentroarticulo
              WHERE  public.far_lote.idarticulo =rfar_articulo.idmodifica
                          and public.far_lote.idcentroarticulo =rfar_articulo.idmodificacentro ;


              FETCH cfar_articulo into rfar_articulo;
      END LOOP;
      close cfar_articulo;


   


return 'true';
END;
$function$
