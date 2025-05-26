CREATE OR REPLACE FUNCTION public.aminsertarbarrabenef(integer, integer, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Esta funcion se llama desde la funcion insertarbarra().*/
DECLARE
idvinbenef alias for $1;
tipodocbenef alias for $2;
nrodocbenef alias for $3;
tipodoctitu alias for $4;
nrodoctitu alias for $5;
barraBD RECORD;
barrita RECORD;
terminacion boolean;
proxima integer;
BEGIN
terminacion = true;
SELECT INTO barraBD * FROM barras WHERE  barras.tipodoc=tipodocbenef AND barras.nrodoc= nrodocbenef;
IF NOT FOUND then /*No existe ninguna barra para el beneficiario*/
	IF idvinbenef=1 then /*El beneficiario es el conyuge*/
       INSERT INTO barras VALUES (1,1,tipodocbenef,nrodocbenef) ;
    ELSE
        IF idvinbenef=4 THEN /*El beneficiario es Padre a Cargo*/
					INSERT INTO barras VALUES (21,1,tipodocbenef,nrodocbenef);
	    ELSE
	        IF idvinbenef=5 THEN /*El beneficiario es madre a Cargo*/
				INSERT INTO barras VALUES (22,1,tipodocbenef,nrodocbenef);
	        ELSE /*El beneficiario es menor a cargo, hijo, nieto, etc*/
	            SELECT INTO barrita * FROM tbarras WHERE tbarras.nrodoctitu=nrodoctitu AND tbarras.tipodoctitu=tipodoctitu;
				IF NOT FOUND THEN
                   proxima=2;
                   ELSE
                   proxima=barrita.siguiente;
                END IF;
				INSERT INTO barras VALUES (proxima,1,tipodocbenef,nrodocbenef);
				UPDATE tbarras SET siguiente=proxima + 1 WHERE tbarras.nrodoctitu=nrodoctitu AND tbarras.tipodoctitu=tipodoctitu;	
			END IF;
        END IF;
    
	END IF;
				
ELSE /*El beneficiario si existe*/
     IF barrasBD.barra >= 30 THEN
        terminacion=false;
     ELSE
    	IF idvinbenef=1 then /*El beneficiario es el conyuge*/
              UPDATE barras SET prioridad=1,barra=1 WHERE nrodoc=nrodocbenef AND tipodoc=tipodocbenef;	
        ELSE
            IF idvinbenef=4	THEN
                UPDATE barras SET prioridad=1,barra=21 WHERE nrodoc=nrodocbenef AND tipodoc=tipodocbenef;	
            ELSE
                 IF idvinbenef=5 THEN
			        UPDATE barras SET prioridad=1,barra=22 WHERE nrodoc=nrodocbenef AND tipodoc=tipodocbenef;	
                 ELSE
                       SELECT INTO barrita * FROM tbarras WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
                       IF NOT FOUND THEN
                          proxima=2;
                       ELSE
                           proxima=barrita.siguiente;
                       END IF;
                       UPDATE tbarras SET siguiente=proxima+1	WHERE tbarras.nrodoctitu=nrodoctitu AND tbarras.tipodoctitu=tipodoctitu;
			           UPDATE barras SET prioridad=1,barra=proxima	WHERE barras.nrodoc=nrodocbenef AND barras.tipodoc=tipodocbenef;	
                 END IF;
           END IF;
        END IF;
     END IF;
END IF;
return 	terminacion;					
END;
$function$
