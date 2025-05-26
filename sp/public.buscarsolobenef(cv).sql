CREATE OR REPLACE FUNCTION public.buscarsolobenef(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  
rec RECORD;
aux varchar;
nro integer;
BEGIN
DELETE FROM tcarnet;
   	   nro =1;	
	   FOR rec IN SELECT  persona.nrodoc,persona.tipodoc,persona.barra,persona.nombres,persona.apellido,persona.fechafinos FROM benefsosunc 
	    join persona on (persona.nrodoc = benefsosunc.nrodoc and persona.tipodoc = benefsosunc.tipodoc) 
 LOOP
			if nro = 1 
				then
					aux = concat(rec.nrodoc,trim(' ' from to_char(rec.barra,'99')));
					INSERT INTO tcarnet (idafil1,nomape1,vto1,nro1,barra1,usuario) VALUES (concat(rec.nrodoc,trim(' ' from to_char(rec.barra,'99'))),concat(rec.apellido,', ',rec.nombres),rec.fechafinos,rec.nrodoc,rec.barra,$1);
					nro = 2;					
				else
	
					UPDATE tcarnet SET idafil2 = concat(rec.nrodoc,trim(' '  from to_char(rec.barra,'99'))), nomape2=concat(rec.apellido,', ',rec.nombres), vto2=rec.fechafinos, nro2=rec.nrodoc, barra2 = rec.barra WHERE idafil1 = aux;
					nro =1;
			end if;	   
   	   END LOOP ;
   	 	
	
   RETURN 'true';
END;
$function$
