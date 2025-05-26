CREATE OR REPLACE FUNCTION public.far_articulos_sin_controlar_sa(bigint, bigint)
 RETURNS SETOF t_articulos_sin_controlar_sa
 LANGUAGE plpgsql
AS $function$DECLARE
       rarticulosscsa t_articulos_sin_controlar_sa;
       rsabierto RECORD;

BEGIN

    SELECT INTO rsabierto * FROM far_stockajusteitem  NATURAL JOIN far_articuloagrupador               
                            JOIN far_stockajusteestado USING(idstockajuste,idcentrostockajuste)
                            WHERE idstockajusteestadotipo=1 AND nullvalue(eaefechafin) AND idagrupador =  $2;
    IF FOUND THEN 
       FOR rarticulosscsa IN
       SELECT text_concatenar(concat(sa.idstockajuste,'-',sa.idcentrostockajuste)) as idstockajuste,far_articulo.idarticulo,
           far_articulo.idcentroarticulo,
           concat(idarticulo,'-',idcentroarticulo) as codarticulo,adescripcion,acodigobarra,lstock,idagrupador,
           agrdescripcion,uddescripcion
           FROM far_stockajuste as sa NATURAL JOIN far_stockajusteitem 
           NATURAL JOIN far_articulo NATURAL JOIN far_lote NATURAL JOIN far_articuloagrupador NATURAL JOIN far_agrupador 
            LEFT JOIN (SELECT text_concatenar(concat(uddescripcion,' - ')) as uddescripcion,idarticulo,idcentroarticulo
            FROM far_articuloubicacionsucursal
            LEFT JOIN far_ubicacionsucursal USING(idubicacionsucursal,idcentroubicacionsucursal)
            WHERE nullvalue(ausfechafin)
            GROUP BY idarticulo,idcentroarticulo) as fus USING(idarticulo,idcentroarticulo)
           WHERE nullvalue(aafechafin) AND  idcentrolote = $1 AND idagrupador = $2 AND (lstock <> 0 AND aactivo ) 
            AND (idarticulo,idcentroarticulo)  NOT IN (SELECT idarticulo,idcentroarticulo
              FROM far_stockajusteitem  NATURAL JOIN far_articuloagrupador               
              JOIN far_stockajusteestado USING(idstockajuste,idcentrostockajuste)
              WHERE idstockajusteestadotipo=1 AND nullvalue(eaefechafin) AND idagrupador = $2 )
          GROUP BY idagrupador,agrdescripcion,uddescripcion,idarticulo,idcentroarticulo,adescripcion,acodigobarra,lstock

     loop

         return next rarticulosscsa;
      end loop;
   ELSE 
      RAISE EXCEPTION 'No existen comprobantes de ajuste abiertos para controlar. ';
		
   END IF; 


END;
$function$
