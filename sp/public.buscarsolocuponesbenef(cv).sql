CREATE OR REPLACE FUNCTION public.buscarsolocuponesbenef(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  
rec RECORD;
aux varchar;
nro integer;
BEGIN
DELETE FROM tcarnet;
   	   nro =1;	
	   FOR rec IN SELECT  persona.nrodoc,persona.barra,persona.fechafinos,tafiliado.idafiliado
				  FROM	(benefsosunc NATURAL JOIN persona) JOIN tafiliado USING (nrodoc, tipodoc) order by benefsosunc.nrodoctitu  LOOP
			if nro = 1 
				then
					aux = rec.nrodoc;
					INSERT INTO tcarnet (idafil1,vto1,nro1,barra1,usuario) VALUES (rec.nrodoc,rec.fechafinos,rec.barra,rec.idafiliado,$1);
					nro = 2;					
				else
					UPDATE tcarnet SET idafil2 = rec.nrodoc,vto2=rec.fechafinos, nro2=rec.idafiliado, barra2 = rec.barra WHERE idafil1 = aux;
					nro =1;
			end if;	   
   	   END LOOP ;
   	 	
	
   RETURN 'true';
END;
$function$
