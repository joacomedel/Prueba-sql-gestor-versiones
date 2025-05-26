CREATE OR REPLACE FUNCTION public.sys_cargarhistocodigobarraarticulodesdemedicamento()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       un record;
       
       rverifica record;	
       
BEGIN 

    OPEN cvalorregistros FOR    SELECT *
				                FROM medicamentosys as ms
				                WHERE  (/*nullvalue(ms.idvalor) AND*/ 
                                    ikfechainformacion >= '2023-01-01')
                                    AND not nullvalue(ms.mcodbarra) 
                                    AND mcodbarra <> mcodbarraarchivo;
				

     FETCH cvalorregistros into un;
     WHILE FOUND LOOP
		PERFORM far_cargarhistoricocodigobarra(concat('{ mnroregistro=',un.mnroregistro,', acodigobarra=',un.mcodbarra,'::varchar, idarticulo=null,idcentroarticulo=null}'));
     FETCH cvalorregistros into un;
     END LOOP;
     close cvalorregistros;
     return 'Listo';
END;
$function$
