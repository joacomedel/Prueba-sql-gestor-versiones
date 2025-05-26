CREATE OR REPLACE FUNCTION public.generarinformenotadebitominutas(character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    reg RECORD;
    resultado BOOLEAN;
    regfac RECORD;
    cursorfac CURSOR FOR
                SELECT  * FROM factura  WHERE idresumen=$1 and anioresumen= $2;
	
BEGIN


open cursorfac;
FETCH cursorfac INTO regfac;

 IF FOUND THEN  --si es un resumen incluido en la minuta
  WHILE FOUND LOOP
	--me fijo si la factura incluida en el resumen tiene algun debito asociado
  	SELECT INTO reg * FROM debitofacturaprestador WHERE nroregistro = regfac.nroregistro AND anio = regfac.anio;

  	IF FOUND THEN --si la factura incluida en el resumen tiene algun debito asociado

		SELECT INTO resultado * from generarinformenotadebito(regfac.nroregistro::varchar,regfac.anio::varchar);

		DELETE FROM ttinformefacturacionitem;  

	END IF;
	FETCH cursorfac INTO regfac;
		
  END LOOP;
 ELSE  --si es una factura que no esta incluida en ningun resumen

	SELECT INTO resultado * from generarinformenotadebito($1,$2);
	DELETE FROM ttinformefacturacionitem;
 END IF;


close cursorfac;

  
return resultado;
END;
$function$
