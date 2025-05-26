CREATE OR REPLACE FUNCTION public.buscarbeneficiarios(character varying, integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
  
rec RECORD;
aux varchar;
nro integer;
BEGIN
	   nro =$3;	
	   FOR rec IN SELECT persona.nrodoc,persona.tipodoc,persona.barra,persona.nombres,persona.apellido,persona.fechafinos FROM (select * from persona where nrodoc = $1 and tipodoc = $2) as titular 
	JOIN benefsosunc 
	ON (benefsosunc.nrodoctitu = titular.nrodoc and benefsosunc.tipodoctitu = titular.tipodoc )
	 join persona 
		on (persona.nrodoc = benefsosunc.nrodoc and persona.tipodoc = benefsosunc.tipodoc) LOOP
			if nro = 1 
				then
					aux = concat(rec.nrodoc,trim(' ' from to_char(rec.barra,'99')));
					INSERT INTO tcarnet (idafil1,nomape1,vto1,nro1,barra1) VALUES (
                    concat(rec.nrodoc,trim(' ' from to_char(rec.barra,'99'))),concat(rec.apellido,', ',rec.nombres),rec.fechafinos,rec.nrodoc,rec.barra);
					nro = 2;					
				else
	
					UPDATE tcarnet SET idafil2 =
                       concat(rec.nrodoc,trim(' '  from to_char(rec.barra,'99'))), nomape2=concat(rec.apellido,', ',rec.nombres), vto2=rec.fechafinos, nro2=rec.nrodoc, barra2 = rec.barra WHERE idafil1 = aux;
					nro =1;
			end if;	   
   	   END LOOP ;
   RETURN nro;
END;
$function$
