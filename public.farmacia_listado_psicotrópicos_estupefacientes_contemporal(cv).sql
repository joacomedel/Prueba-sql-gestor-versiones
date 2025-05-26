CREATE OR REPLACE FUNCTION public."farmacia_listado_psicotrópicos_estupefacientes_contemporal"(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_farmacia_listado_psicotrópicos_estupefacientes_contemporal AS (


        SELECT 
            mcodbarra ,
            monnombre,
            adescripcion,
            mctdescripcion ,
            lstock 
            ,'1-Codigo Barra#mcodbarra@2-Monodroga#monnombre@3-Articulo#adescripcion@4-Lista#mctdescripcion@5-Stock#lstock'::text as mapeocampocolumna 
  
        FROM 
            (SELECT 
                mcodbarra,
                mctdescripcion,
                monnombre

            FROM public.medicamentosys 
              LEFT JOIN medicamentocontroltipo ON (idmedicamentocontroltipo=marcaprodcontrolado)
              NATURAL JOIN valormedicamento
              LEFT JOIN manextra USING (mnroregistro)
              LEFT JOIN monodroga USING (idmonodroga)  
            WHERE true 
                  AND marcaprodcontrolado IS NOT NULL
                  AND CASE WHEN nullvalue(rparam.idmedicamentocontroltipo) 
                  THEN 
                  (
                    marcaprodcontrolado = 2 
                    OR marcaprodcontrolado = 3
                    OR marcaprodcontrolado = 4
                    OR marcaprodcontrolado = 5
                    OR marcaprodcontrolado = 6 
                    OR marcaprodcontrolado = 7
                    OR marcaprodcontrolado = 8
                    OR marcaprodcontrolado = 'A'
                    )
                  ELSE rparam.idmedicamentocontroltipo=marcaprodcontrolado END
                  AND nullvalue(vmfechafin)
            GROUP BY mcodbarra,mctdescripcion,monnombre
            ) as articulo
          
            LEFT join far_articulo as fa ON (acodigobarra=mcodbarra)
            LEFT JOIN (select idarticulo,idcentroarticulo,sum(lstock) as lstock  from far_lote where idcentrolote = centro() 

            GROUP BY idarticulo,idcentroarticulo ) as l on fa.idarticulo = l.idarticulo  AND fa.idcentroarticulo = l.idcentroarticulo  

          WHERE true 
                AND lstock IS NOT NULL 
                AND lstock != 0

          ORDER BY adescripcion
    );
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
      
    
return respuesta;
END;$function$
