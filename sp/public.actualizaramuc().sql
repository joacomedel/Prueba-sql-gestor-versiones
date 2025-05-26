CREATE OR REPLACE FUNCTION public.actualizaramuc()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	alta CURSOR FOR SELECT * FROM amucnovedades 
					WHERE  nullvalue(amucnovedades.anprocesado) AND nullvalue(anerror)  
                    --nrodoc = '27091730'
                    --nullvalue(amucnovedades.anprocesado)
                    ORDER BY ananioingreso,anmesingreso;
	elem RECORD;
	aux RECORD;
	resultado BOOLEAN;
	
BEGIN

OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
resultado = false;


	SELECT INTO aux * FROM afiliauto WHERE nrodoc = elem.nrodoc;  
      
 	IF FOUND  THEN 
    	IF (elem.annovedadalta) THEN
 	    	UPDATE afiliauto SET mutu = 'true', nromutu = elem.nromutu WHERE nrodoc = elem.nrodoc;
        ELSE
        	UPDATE afiliauto SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
            UPDATE benefsosunc SET barramutu = 0, mutual= 'false', nromututitu = 0
								WHERE nrodoctitu = elem.nrodoc; 
        END IF;
    	resultado = true;
    end if;
	
    SELECT INTO aux * FROM afilidoc WHERE nrodoc = elem.nrodoc;    
 	IF FOUND then
    	IF (elem.annovedadalta) THEN
 			UPDATE afilidoc SET mutu = 'true', nromutu = elem.nromutu WHERE nrodoc = elem.nrodoc;
    		
        ELSE
        	UPDATE afilidoc SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
            UPDATE benefsosunc SET barramutu = 0, mutual= 'false', nromututitu = 0
								WHERE nrodoctitu = elem.nrodoc; 
        END IF;
        resultado = true;
    end if;
    SELECT INTO aux * FROM afilinodoc WHERE nrodoc = elem.nrodoc;    
 	IF FOUND then
    	IF (elem.annovedadalta) THEN
 			UPDATE afilinodoc SET mutu = 'true', nromutu = elem.nromutu WHERE nrodoc = elem.nrodoc;
    	ELSE
        	UPDATE afilinodoc SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
            UPDATE benefsosunc SET barramutu = 0, mutual= 'false', nromututitu = 0
								WHERE nrodoctitu = elem.nrodoc; 
        END IF;
        resultado = true;
    
    end if;
    SELECT INTO aux * FROM afilirecurprop WHERE nrodoc = elem.nrodoc;    
 	IF FOUND then
    	IF (elem.annovedadalta) THEN
 			UPDATE afilirecurprop SET mutu = 'true', nromutu = elem.nromutu WHERE nrodoc = elem.nrodoc;
    	ELSE
        	UPDATE afilirecurprop SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
            UPDATE benefsosunc SET barramutu = 0, mutual= 'false', nromututitu = 0
								WHERE nrodoctitu = elem.nrodoc; 
        END IF;
        resultado = true;
    
    end if;
    SELECT INTO aux * FROM afilisos WHERE nrodoc = elem.nrodoc;
 	IF FOUND THEN 
 		IF (elem.annovedadalta)	THEN
            UPDATE afilisos SET mutu = 'true', nromutu = elem.nromutu WHERE nrodoc = elem.nrodoc;
    	ELSE
        	UPDATE afilisos SET mutu = 'false', nromutu = 0 WHERE nrodoc = elem.nrodoc;
            UPDATE benefsosunc SET barramutu = 0, mutual= 'false', nromututitu = 0
								WHERE nrodoctitu = elem.nrodoc; 
        END IF;
    resultado = true;
    end if;
    SELECT INTO aux * FROM benefsosunc WHERE nrodoc = elem.nrodoc;
 	IF FOUND THEN 
 		IF (elem.annovedadalta)	THEN
           UPDATE benefsosunc SET barramutu = elem.barramutu, mutual= 'true', nromututitu = elem.nromutu
           						--,nrodoctitu = elem.nrodoctitu
								WHERE nrodoc = elem.nrodoc ; 

		ELSE
        	UPDATE benefsosunc SET barramutu = 0, mutual= 'false', nromututitu = 0
					WHERE nrodoc = elem.nrodoc; 

        END IF;
    resultado = true;
    end if;
    

    
IF not resultado then 
	UPDATE amucnovedades SET anerror = 'No Existe' WHERE nrodoc =  elem.nrodoc;
ELSE
    UPDATE amucnovedades SET anprocesado = CURRENT_TIMESTAMP WHERE nrodoc =  elem.nrodoc; 
end if;


fetch alta into elem;
END LOOP;
CLOSE alta;
return 'true';
END;
$function$
