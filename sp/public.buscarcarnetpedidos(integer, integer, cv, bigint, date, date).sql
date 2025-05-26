CREATE OR REPLACE FUNCTION public.buscarcarnetpedidos(integer, integer, character varying, bigint, date, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  
rec RECORD;
aux RECORD;
fechafin date;
nomape varchar;
nrodocumento varchar;
barrita integer;
nro integer;
BEGIN

	nro =1;	
	FOR rec IN SELECT DISTINCT *  FROM persona 
		 NATURAL JOIN (SELECT tipodoc,nrodoc,idcargo,idcateg,idlocalidad,idprovincia FROM cargo 
			 NATURAL JOIN depuniversitaria 
			NATURAL JOIN direccion) AS cargo WHERE persona.barra = $2 AND idlocalidad = $4 AND fechafinos >= $5 AND fechafinos <= $6 ORDER BY apellido  
	LOOP
		IF nro = 1 THEN
			fechafin = rec.fechafinos;
			barrita = rec.barra;
			nrodocumento = rec.nrodoc;
			nomape = concat(rec.apellido,', ',rec.nombres);
			nro = 2;					
		ELSE
			INSERT INTO tcupones (nomape1,vto1,nro1,barra1,usuario,nomape2,vto2,nro2,barra2) VALUES (nomape,fechafin,nrodocumento,barrita,$3,concat(rec.apellido,',',rec.nombres),rec.fechafinos,rec.nrodoc,rec.barra);
			nro =1;
		END IF;
   	--Inserto todos los beneficiarios activos de ese titular
        FOR aux IN SELECT * FROM persona NATURAL JOIN benefsosunc JOIN tafiliado USING(nrodoc,tipodoc) WHERE 
                                                         benefsosunc.nrodoctitu = rec.nrodoc 
                                                        AND benefsosunc.tipodoctitu = rec.tipodoc  
                                                        AND benefSosunc.idestado <> 4 LOOP	
		IF nro = 1 THEN
			fechafin = aux.fechafinos;
			barrita = aux.barra;
			nrodocumento = aux.nrodoc;
			nomape = concat(aux.apellido,', ',aux.nombres);
			nro = 2;					
		ELSE
			INSERT INTO tcupones (nomape1,vto1,nro1,barra1,usuario,nomape2,vto2,nro2,barra2) VALUES (nomape,fechafin,nrodocumento,barrita,$3,concat(aux.apellido,', ',aux.nombres),aux.fechafinos,aux.nrodoc,aux.barra);
			nro =1;
		END IF; 
   	   END LOOP ;
   END LOOP ; 	

	
   RETURN 'true';
END;
$function$
