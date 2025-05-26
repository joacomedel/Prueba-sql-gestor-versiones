CREATE OR REPLACE FUNCTION public.buscarcarnetpedidos(integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  
rec RECORD;
aux varchar;
nro integer;
BEGIN

	   nro =1;	
	   FOR rec IN SELECT * FROM persona WHERE barra = $2 LOOP
			if nro = 1 
				then
					INSERT INTO tcupones (nomape1,vto1,nro1,barra1,usuario) VALUES (
                       concat(rec.apellido,', ',rec.nombres),rec.fechafinos,rec.nrodoc,rec.barra,$3);
					nro = 2;					
				else
	
					UPDATE tcupones SET nomape2=concat(rec.apellido,', ',rec.nombres), vto2=rec.fechafinos, nro2=rec.nrodoc, barra2 = rec.barra WHERE nro1 <> '' AND usuario = $3 ;
					nro =1;
			end if;	   
   	   END LOOP ;
if $1 > 0 
	then	
   	   nro =1;	
	   FOR rec IN SELECT persona.nrodoc,persona.tipodoc,persona.barra,persona.nombres,persona.apellido,persona.fechafinos FROM (select * from persona where barra = $2) as titular 
	JOIN benefsosunc 
	ON (benefsosunc.nrodoctitu = titular.nrodoc and benefsosunc.tipodoctitu = titular.tipodoc )
	 join persona 
		on (persona.nrodoc = benefsosunc.nrodoc and persona.tipodoc = benefsosunc.tipodoc) order by benefsosunc.nrodoctitu LOOP
			if nro = 1 
				then
					INSERT INTO tcupones (nomape1,vto1,nro1,barra1,usuario) VALUES (concat(rec.apellido,', ',rec.nombres),rec.fechafinos,rec.nrodoc,rec.barra,$3);
					nro = 2;					
				else
	
					UPDATE tcupones SET nomape2=concat(rec.apellido,', ',rec.nombres), vto2=rec.fechafinos, nro2=rec.nrodoc, barra2 = rec.barra WHERE nro1 <> '' AND usuario = $3 ;
					nro =1;
			end if;	   
   	   END LOOP ;
   	 	
end if;
	
   RETURN 'true';
END;
$function$
