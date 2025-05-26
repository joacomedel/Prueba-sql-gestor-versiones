CREATE OR REPLACE FUNCTION public.sys_cargarfar_articulodesdemedicamentosys()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       unvalormed record;
       verifica RECORD;
       
BEGIN 
    --27-09-19 solo guardo los medicamentos que vinieron en kairos y que no se procesaron (nullvalue(ms.idvalor))
     OPEN cvalorregistros FOR 
                SELECT 
                    ms.lnombre,
                    ms.mnroregistro,
                    ms.idlaboratorio,
                    ms.mcodbarra,ms.idfarmtipoventa,ms.mtroquel,ms.mpresentacion,ms.mnombre
                FROM medicamentosys as ms
                LEFT JOIN far_medicamento USING(mnroregistro)
                WHERE  
                    nullvalue(far_medicamento.mnroregistro)
                    AND nullvalue(ms.idvalor)
                    AND not nullvalue(ms.mcodbarra) 
                GROUP BY ms.lnombre,ms.mnroregistro,ms.idlaboratorio,ms.mcodbarra,ms.idfarmtipoventa,ms.mtroquel,ms.mpresentacion,ms.mnombre;
                

     FETCH cvalorregistros into unvalorreg;
     WHILE FOUND LOOP
            
            -- Vinculo entre medicamentosys y far_articulo
            SELECT INTO verifica * FROM far_medicamento WHERE mnroregistro = unvalorreg.mnroregistro AND nomenclado;
            
            IF NOT FOUND THEN
                SELECT * INTO  unvalormed FROM far_cargarmedicamento(unvalorreg.mnroregistro);  

            ELSE 
                -- revisar si es necesario un update del vinculo    
            END IF;
        
     FETCH cvalorregistros into unvalorreg;
     END LOOP;
     close cvalorregistros;
     return 'Listo';
END;
$function$
