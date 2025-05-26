CREATE OR REPLACE FUNCTION public.modificarcaracteristicaafilsosunc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
        rcaracteristica record;      
        resp boolean;
      

BEGIN

SELECT INTO rcaracteristica *  FROM tcaracteristica;
IF FOUND THEN 
		IF(not nullvalue(rcaracteristica.caract)) THEN
       
	INSERT INTO tcaracteristica(caract,idprovincia,idlocalidad)
        VALUES(rcaracteristica.caract,rcaracteristica.idprovincia,rcaracteristica.idlocalidad);
                END IF;

                

 END IF;

return 'true';
END;$function$
