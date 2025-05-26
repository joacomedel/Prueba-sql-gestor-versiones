CREATE OR REPLACE FUNCTION public.far_migrarmedicamentoplancoberturafarmacia()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  	cursormono CURSOR FOR SELECT *
                              FROM monodroga LEFT JOIN plancoberturafarmacia AS pcf USING(idmonodroga)    
                              WHERE nullvalue(pcf.idmonodroga);


	rmono RECORD;
	

BEGIN

    OPEN cursormono;
    FETCH cursormono INTO rmono;
    WHILE  found LOOP
--Dani cambio el 09/01/2024 de 0.55 a 0.4
           insert into plancoberturafarmacia(idmonodroga,fechafinvigencia,multiplicador)
           values(rmono.idmonodroga,null,0.4);
          
    FETCH cursormono into rmono;
    END LOOP;
    close cursormono;


return 'true';
END;
$function$
