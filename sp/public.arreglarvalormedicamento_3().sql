CREATE OR REPLACE FUNCTION public.arreglarvalormedicamento_3()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       cmedicamento refcursor;
       unmedicamento record;
BEGIN
     -- 1 - se buscan topdos los medicamentos que NO tienen mas de un  valor vigente
      OPEN cmedicamento FOR
           SELECT count(*) , mnroregistro
           FROM valormedicamento
           WHERE nullvalue(vmfechafin)
          --       and mnroregistro =50919
           group by mnroregistro
           having count(*) > 1 ;
/*SELECT *
     FROM far_articulo
WHERE (idarticulo,idcentroarticulo) NOT IN (
     SELECT idarticulo,idcentroarticulo
     FROM far_precioarticulo
     WHERE nullvalue(pafechafin)
              );
*/


     -- 2 se recorre cada uno de los medicamentos y queda como vigente el ULTIMO VALOR encontrado
     FETCH cmedicamento into unmedicamento;
     WHILE FOUND LOOP
           UPDATE valormedicamento SET vmfechafin = now()
           WHERE valormedicamento.mnroregistro = unmedicamento.mnroregistro
                 and nullvalue(vmfechafin)
                 and idvalor NOT IN (
                     SELECT MAX (idvalor)
                     FROM valormedicamento
                     WHERE mnroregistro = unmedicamento.mnroregistro
                     group by mnroregistro

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
