CREATE OR REPLACE FUNCTION public.cambiarestadoinformecobranza()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
	cursorinfocobranza CURSOR FOR SELECT * FROM tempinformecobranza;
	cursorinforme refcursor;
--RECORD 
	reginfocobranza RECORD;
	reginforme RECORD;
        resinfounc RECORD; 
--VARIABLES
       resultado BOOLEAN;


BEGIN

OPEN cursorinfocobranza;
FETCH cursorinfocobranza into reginfocobranza;
     WHILE  found LOOP

	IF (reginfocobranza.sincronizar = true) THEN ---sincronizo el informe 
	   
            	PERFORM cambiarestadoinformefacturacion(reginfocobranza.nroinforme,reginfocobranza.idcentroinformefacturacion,8,'Modificada al ser sincronizada con Multivac correctamente. ');

                UPDATE informefacturacioncobranza set idcomprobantecobranzamultivac =reginfocobranza.idcomprobantecobranzamultivac
                WHERE nroinforme=reginfocobranza.nroinforme AND   
                informefacturacioncobranza.idcentroinformefacturacion=reginfocobranza.idcentroinformefacturacion;
         


	ELSE --Si no sincronizo borro el informe y sus items de la base de datos
		 --veo que tipo de informe es. KR 19-06-2014
                    SELECT INTO resinfounc  * FROM informefacturacioncobranza	NATURAL JOIN informefacturacioncobranzaunc 
			WHERE nroinforme = reginfocobranza.nroinforme AND informefacturacioncobranza.idcentroinformefacturacion = reginfocobranza.idcentroinformefacturacion; 
                    IF NOT FOUND THEN -- Si NO es un informe de la unc de asistencial y turismo entonces elimino todo rastro de su existencia
			DELETE FROM informefacturacioncobranza 
			WHERE informefacturacioncobranza.nroinforme = reginfocobranza.nroinforme AND informefacturacioncobranza.idcentroinformefacturacion = reginfocobranza.idcentroinformefacturacion;

			DELETE FROM informefacturacionitem 
			WHERE informefacturacionitem.nroinforme = reginfocobranza.nroinforme AND informefacturacionitem.idcentroinformefacturacion = reginfocobranza.idcentroinformefacturacion;

			DELETE FROM informefacturacionestado
			WHERE informefacturacionestado.nroinforme = reginfocobranza.nroinforme AND informefacturacionestado.idcentroinformefacturacion = reginfocobranza.idcentroinformefacturacion;

			DELETE FROM informefacturacion
			WHERE informefacturacion.nroinforme = reginfocobranza.nroinforme AND informefacturacion.idcentroinformefacturacion = reginfocobranza.idcentroinformefacturacion;

	          END IF;			

		
		
	END IF;

     FETCH cursorinfocobranza into reginfocobranza;
     END LOOP;
CLOSE cursorinfocobranza;



return true;
end;
$function$
