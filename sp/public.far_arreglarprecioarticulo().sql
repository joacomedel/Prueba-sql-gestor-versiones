CREATE OR REPLACE FUNCTION public.far_arreglarprecioarticulo()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cmedicamento refcursor;
       unmedicamento record;
BEGIN
     -- 1 - se buscan topdos los articulos que tienen mas de un  valor vigente
      OPEN cmedicamento FOR
           select idarticulo,idcentroarticulo,count(*) 
		from far_precioarticulo  
		where nullvalue(pafechafin) 
		group by idarticulo,idcentroarticulo 
		having count(*)> 1;

/*SELECT *
     FROM far_articulo
WHERE (idarticulo,idcentroarticulo) NOT IN (
     SELECT idarticulo,idcentroarticulo
     FROM far_precioarticulo
     WHERE nullvalue(pafechafin)
              );
*/


     -- 2 se recorre cada uno de los articulos y queda como vigente el ULTIMO VALOR encontrado
     FETCH cmedicamento into unmedicamento;
     WHILE FOUND LOOP
           UPDATE far_precioarticulo SET pafechafin = now()
           WHERE far_precioarticulo.idarticulo = unmedicamento.idarticulo 
                 AND far_precioarticulo.idcentroarticulo =  unmedicamento.idcentroarticulo
                 and nullvalue(pafechafin)
                 and idprecioarticulo NOT IN (
                      SELECT MAX(idprecioarticulo) as idprecioarticulo
                      FROM far_precioarticulo
                      WHERE idarticulo = unmedicamento.idarticulo 
                      AND idcentroarticulo =  unmedicamento.idcentroarticulo
                      and nullvalue(pafechafin)
                      group by idarticulo,idcentroarticulo

             );
             /*UPDATE far_precioarticulo SET pafechafin = null
           WHERE far_precioarticulo.idarticulo = unmedicamento.idarticulo 
                 AND far_precioarticulo.idcentroarticulo =  unmedicamento.idcentroarticulo
                 
                 and idprecioarticulo NOT IN (
                     SELECT MAX(idprecioarticulo) as idprecioarticulo
                     FROM far_precioarticulo
                     WHERE idarticulo = unmedicamento.idarticulo 
                      AND idcentroarticulo =  unmedicamento.idcentroarticulo
                      AND idcentroprecioarticulo = 1
                     group by idarticulo,idcentroarticulo

             );*/


            FETCH cmedicamento into unmedicamento;
     END LOOP;
     close cmedicamento;
     return 'Listo';
END;
$function$
