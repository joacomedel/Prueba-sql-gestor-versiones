CREATE OR REPLACE FUNCTION public.buscarcuponespedidos(integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  
rec RECORD;
aux varchar;
nro integer;
BEGIN

	   nro =1;	
	   FOR rec IN SELECT persona.nrodoc,persona.barra,persona.fechafinos,tafiliado.idafiliado
		FROM	tafiliado NATURAL JOIN persona 	WHERE persona.barra =$2 order by persona.nrodoc LOOP
			if nro = 1 
				then
					aux = rec.nrodoc;
					INSERT INTO tcarnet (idafil1,vto1,nro1,barra1,usuario) VALUES (rec.nrodoc,rec.fechafinos,rec.barra,rec.idafiliado,$3);
					nro = 2;					
				else
	
					UPDATE tcarnet SET idafil2 = rec.nrodoc, vto2=rec.fechafinos, nro2=rec.idafiliado, barra2 = rec.barra WHERE idafil1 = aux;
					nro =1;
			end if;	   
   	   END LOOP ;
if $1 > 0 
	then	
   	   nro =1;	
	   FOR rec IN SELECT persona.nrodoc,persona.barra,persona.fechafinos,tafiliado.idafiliado FROM (select * from persona where barra = $2) as titular
	JOIN benefsosunc ON (benefsosunc.nrodoctitu = titular.nrodoc and benefsosunc.tipodoctitu = titular.tipodoc )
	 join persona on (persona.nrodoc = benefsosunc.nrodoc and persona.tipodoc = benefsosunc.tipodoc) JOIN tafiliado ON (tafiliado.nrodoc = benefsosunc.nrodoc and tafiliado.tipodoc = benefsosunc.tipodoc)order by benefsosunc.nrodoctitu LOOP
			if nro = 1 
				then
					aux = rec.nrodoc;
					INSERT INTO tcarnet (idafil1,vto1,nro1,barra1,usuarioi) VALUES (rec.nrodoc,rec.fechafinos,rec.idafiliado,rec.barra,$3);
					nro = 2;					
				else
	
					UPDATE tcarnet SET idafil2 = rec.nrodoc, vto2=rec.fechafinos, nro2=rec.idafiliado, barra2 = rec.barra WHERE idafil1 = aux;
					nro =1;
			end if;	   
   	   END LOOP ;
   	 	
end if;
	
   RETURN 'true';
END;
$function$
