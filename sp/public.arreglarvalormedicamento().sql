CREATE OR REPLACE FUNCTION public.arreglarvalormedicamento()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       cvalormedicamento refcursor;
       unvalormed record;
       antmnroregistro integer;
       antidvalor integer;
       ultimafechafin TIMESTAMP;
BEGIN

     antmnroregistro = 0;
     antidvalor = 0;
     OPEN cvalormedicamento FOR
          SELECT * FROM  valormedicamento 
          --WHERE mnroregistro = 31831 AND idvalor >= 1702405 
          --OR mnroregistro = 48545
          ORDER BY mnroregistro , idvalor;

     FETCH cvalormedicamento into unvalormed;
     WHILE FOUND LOOP
            if (unvalormed.mnroregistro <> antmnroregistro )THEN
               antmnroregistro = unvalormed.mnroregistro;
               antidvalor = unvalormed.idvalor;
               ultimafechafin = unvalormed.vmfechafin;
            ELSE
                IF(unvalormed.vmfechaini <> ultimafechafin ) THEN
                   -- el valor analizado tiene fecha inicio menor a la ultima fecha fin
                      UPDATE valormedicamento SET vmfechafin = unvalormed.vmfechaini
                      WHERE idvalor=antidvalor and mnroregistro =unvalormed.mnroregistro ;
                END IF;
            
            END IF;
           antmnroregistro = unvalormed.mnroregistro;
           antidvalor = unvalormed.idvalor;
           ultimafechafin = unvalormed.vmfechafin;
          
            FETCH cvalormedicamento into unvalormed;
     END LOOP;
     close cvalormedicamento;
     return 'Listo';
END;
$function$
