CREATE OR REPLACE FUNCTION public.sys_cargarmedicamentodesdemedicamentosys()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       cvalorregistros refcursor;
       unvalorreg record;
       unvalormed record;
       rverifica record;	
    
/*
CAMBIOS 


*/   
BEGIN 
	
     OPEN cvalorregistros FOR 
     			SELECT 
     				ms.lnombre,
     				ms.mnroregistro,
     				ms.idlaboratorio,
     				ms.mcodbarra,
     				ms.idfarmtipoventa,
     				ms.mtroquel,
     				ms.mpresentacion,
     				ms.mnombre,
     				ms.mbaja
     		
				FROM medicamentosys as ms
				LEFT JOIN medicamento USING(mnroregistro)
				WHERE  
					(nullvalue(medicamento.mnroregistro) OR (nullvalue(ms.idvalor) 
					AND ikfechainformacion >= '2023-01-01'))
                    AND not nullvalue(ms.mcodbarra) 
                    AND ms.msactivo
				GROUP BY ms.lnombre,ms.mnroregistro,ms.idlaboratorio,ms.mcodbarra,ms.idfarmtipoventa,ms.mtroquel,ms.mpresentacion,ms.mnombre,ms.mbaja;

     FETCH cvalorregistros into unvalorreg;
     WHILE FOUND LOOP
			
			SELECT INTO unvalormed * FROM laboratorio WHERE idlaboratorio = unvalorreg.idlaboratorio;
			-- Si no existe el laboratorio se carga
			IF NOT FOUND THEN
				INSERT INTO laboratorio (idlaboratorio,lnombre) VALUES(unvalorreg.idlaboratorio,unvalorreg.lnombre);
			END IF;

			UPDATE medicamento 
				SET 
					idlaboratorio = unvalorreg.idlaboratorio
			 		,idfarmtipoventa = unvalorreg.idfarmtipoventa
			 		,mtroquel = unvalorreg.mtroquel
			 		,mpresentacion = unvalorreg.mpresentacion
			 		,mnombre = unvalorreg.mnombre
				WHERE 
					mnroregistro = unvalorreg.mnroregistro
				 	AND nomenclado = true;
			-- si no existe para hacerle update se crea 
            IF NOT FOUND THEN 
					INSERT INTO medicamento (mnroregistro,idlaboratorio,mcodbarra,idfarmtipoventa,mtroquel,mpresentacion,mnombre)
					VALUES (unvalorreg.mnroregistro,unvalorreg.idlaboratorio,unvalorreg.mcodbarra,unvalorreg.idfarmtipoventa,unvalorreg.mtroquel,unvalorreg.mpresentacion,unvalorreg.mnombre);
			END IF;

     FETCH cvalorregistros into unvalorreg;
     END LOOP;
     close cvalorregistros;
     return 'Listo';
END;
$function$
