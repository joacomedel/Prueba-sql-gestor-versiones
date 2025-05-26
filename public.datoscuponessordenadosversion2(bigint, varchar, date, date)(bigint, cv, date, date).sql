CREATE OR REPLACE FUNCTION public."datoscuponessordenadosversion2(bigint, varchar, date, date)"(bigint, character varying, date, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
    rec RECORD;
    aux RECORD;
    bandera integer;
	fechafin date;
	idafil varchar;
	barrita integer;
	nrodocantes varchar;
	

BEGIN
bandera = 1;
--Busco el titular en person, segun la barra que han mandado
 FOR rec IN SELECT DISTINCT tipodoc, fechafinos, idafiliado, barra, nrodoc  FROM persona 
	 NATURAL JOIN tafiliado 
	 NATURAL JOIN (SELECT tipodoc,nrodoc,idlocalidad,idprovincia,cargo.fechafinlab FROM cargo
			 NATURAL JOIN depuniversitaria 
			NATURAL JOIN direccion) AS cargo
            WHERE idlocalidad = $1
            /*AND fechafinlab >= $3 AND fechafinlab <= $4*/
            AND fechafinos >= $3 AND fechafinos <= $4
            AND fechafinos >  '2008-04-30' /*CURRENT_DATE*/

--Saco los que se vencen el 29/10/2008 que no tienen hijos con prorrogas
--presentadas en el 2008. Esto lo hago porque suponemos que estos afiliados
--ya retiraron sus cupones en la segunda emision del anio pasado.
--AND (fechafinos != '2008-10-29' OR (nrodoc, tipodoc) in (select persona.nrodoc,persona.tipodoc from persona join benefsosunc on(benefsosunc.nrodoctitu=persona.nrodoc and benefsosunc.tipodoctitu=persona.tipodoc) join prorroga on(prorroga.nrodoc=benefsosunc.nrodoc and prorroga.tipodoc=benefsosunc.tipodoc) where extract(year from fechaemision) = 2008 and persona.fechafinos='2008-10-29'))
--FILTRO ANULADO. ERA TEMPORAL



           --excluimos a los afiliados con actas de defuncion cargadas 
           AND (nrodoc, tipodoc) not in (select nrodoc, tipodoc from actasdefun)
--AND barra = 32
            ORDER BY idafiliado
	LOOP
	IF bandera = 1 THEN
		fechafin = rec.fechafinos;
		idafil = rec.idafiliado;
		barrita = rec.barra;
		nrodocantes = rec.nrodoc;
		--INSERT INTO tcupones (vto1,nro1,barra1,nomape1,usuario) VALUES (rec.fechafinos,rec.idafiliado,rec.barra,rec.nrodoc,$2);
		bandera = 2;					
	ELSE
		INSERT INTO tcupones (vto1,nro1,barra1,nomape1,vto2,nro2,barra2,nomape2,usuario) VALUES (fechafin,idafil,barrita,nrodocantes,rec.fechafinos,rec.idafiliado,rec.barra,rec.nrodoc,$2);
		--UPDATE tcupones SET vto2=rec.fechafinos, nro2=rec.idafiliado, barra2 = rec.barra, nomape2 = rec.nrodoc WHERE nro1 <> '';
		bandera =1;
	END IF;	
   
	--Inserto todos los beneficiarios activos de ese titular
        FOR aux IN SELECT * FROM persona NATURAL JOIN benefsosunc JOIN tafiliado USING(nrodoc,tipodoc) WHERE 
                                                         benefsosunc.nrodoctitu = rec.nrodoc 
                                                        AND benefsosunc.tipodoctitu = rec.tipodoc  
                                                        AND benefSosunc.idestado <> 4 
                                                        /*Agrego que filtre los beneficiaris cuya fechafinos < 30/04/2008*/
                                                        AND persona.fechafinos > '2008-04-30' LOOP
		IF bandera = 1 THEN
			fechafin = aux.fechafinos;
			idafil = aux.idafiliado;
			barrita = aux.barra;
			nrodocantes = aux.nrodoc;
			--INSERT INTO tcupones (vto1,nro1,barra1,nomape1,usuario) VALUES (aux.fechafinos,aux.idafiliado,aux.barra,aux.nrodoc,$2);
			bandera = 2;					
		ELSE
			INSERT INTO tcupones (vto1,nro1,barra1,nomape1,vto2,nro2,barra2,nomape2,usuario) VALUES (fechafin,idafil,barrita,nrodocantes,aux.fechafinos,aux.idafiliado,aux.barra,aux.nrodoc,$2);
			--UPDATE tcupones SET vto2=aux.fechafinos, nro2=aux.idafiliado, barra2 = aux.barra, nomape2 = aux.nrodoc WHERE nro1 <> '';
			bandera =1;
		END IF;	
        END LOOP ;
 END LOOP ;

RETURN 'true';
END;
$function$
