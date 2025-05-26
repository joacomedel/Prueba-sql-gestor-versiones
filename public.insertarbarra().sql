CREATE OR REPLACE FUNCTION public.insertarbarra()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	benefBD RECORD;
	benefT RECORD;
	barrasBD RECORD;
	barrasPer smallint;
	barrita RECORD;
	proxima integer;
	terminacion boolean;
	reci RECORD;
    --comienzo afiliar ASI
	tafil RECORD;
	auxi RECORD;
	barraasi int8;
	--fin afiliar ASI

BEGIN

terminacion='true';

SELECT INTO benefT * FROM bene;
SELECT INTO reci * FROM afilreci WHERE  benefT.tipodoctitu = tipodoc AND benefT.nrodoctitu = nrodoc;
if FOUND then
		SELECT INTO terminacion * FROM insertarbarrareciprocidad();
	else
		SELECT INTO barrasBD * FROM barras WHERE  benefT.tipodoc = tipodoc AND benefT.nrodoc = nrodoc;
		IF NOT FOUND then
				IF (benefT.idvin=1 OR benefT.idvin = 8) 			 then 
						INSERT INTO barras VALUES (1,1,benefT.tipodoc,benefT.nrodoc) ;
						barraasi = 1; --Afiliar Asi
				END IF;
				IF benefT.idvin=4 
					then 
					INSERT INTO barras VALUES (21,1,benefT.tipodoc,benefT.nrodoc);
					barraasi = 21; --Afiliar Asi
				 END IF;
				IF benefT.idvin=5 
					then 
						INSERT INTO barras VALUES (22,1,benefT.tipodoc,benefT.nrodoc);
						barraasi = 22; --Afiliar Asi
				END IF;
				IF benefT.idvin <> 1 AND  benefT.idvin <> 4
				AND  benefT.idvin <> 5 AND benefT.idvin <> 8 THEN
						SELECT INTO barrita * FROM tbarras WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
						proxima=barrita.siguiente;
						INSERT INTO barras VALUES (proxima,1,benefT.tipodoc,benefT.nrodoc);
						UPDATE tbarras SET nrodoctitu=benefT.nrodoctitu,tipodoctitu=benefT.tipodoctitu,siguiente=(proxima+1) WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;	
						barraasi = proxima; --Afiliar Asi
				END IF; 
			else
			/*Modifico MaLaPi 14/11/2008. En teoria no importa cual es la barra que tiene, solo
            en cual debe quedar seguin el vinculo.
            13/12/2010 MaLaPi. Modifico para que si el afiliado tiene asignada una barra no se la modifique,
            siempre que se trate de un hijo/a  Meno a cargo, etc*/
				IF benefT.idvin=1 OR benefT.idvin = 8 then
                UPDATE barras SET nrodoc=benefT.nrodoc,tipodoc=benefT.tipodoc,prioridad=1,barra=1
                   WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc;	
                         barraasi = 1; --Afiliar Asi	
			    END IF;
				IF benefT.idvin=4 then
				    UPDATE barras SET nrodoc=benefT.nrodoc,tipodoc=benefT.tipodoc,prioridad=1,barra=21
                           WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc;
                           barraasi = 21; --Afiliar Asi	
				END IF;
				IF benefT.idvin=5 then
				         UPDATE barras SET nrodoc=benefT.nrodoc,tipodoc=benefT.tipodoc,prioridad=1,barra=22
                                WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc;	
                          barraasi = 22; --Afiliar Asi
				END IF;
				SELECT INTO barrasPer barra from persona WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc;	
				
				IF benefT.idvin <> 1 AND  benefT.idvin <> 4
				AND  benefT.idvin <> 5 AND benefT.idvin <> 8 AND barrasPer > 30 THEN
						SELECT INTO barrita * FROM tbarras WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
		   			   proxima=barrita.siguiente;
								UPDATE tbarras
									SET
										nrodoctitu=benefT.nrodoctitu,
										tipodoctitu=benefT.tipodoctitu,
										siguiente=proxima+1
								WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
								UPDATE barras
									SET
										nrodoc=benefT.nrodoc,
										tipodoc=benefT.tipodoc,
										prioridad=1,
										barra=proxima
								WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc;	
						barraasi = proxima; --Afiliar Asi
						END IF;
		END IF;
end if;
--Comienzo afiliar ASI
SELECT INTO tafil * FROM tafiliado where nrodoc = benefT.nrodoctitu;
SELECT INTO auxi * FROM tafiliado where nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;
IF FOUND THEN
   UPDATE tafiliado SET benef = TRUE, idafiliado = concat(tafil.idafiliado , '-' , to_char (barraasi,'00'))
          WHERE nrodoc = benefT.nrodoc AND tipodoc = benefT.tipodoc;
ELSE
   INSERT INTO tafiliado (benef,nrodoc,tipodoc,tipoafil,idafiliado)
   VALUES (TRUE,benefT.nrodoc,benefT.tipodoc,benefT.nrodoctitu,concat(tafil.idafiliado,'-' ,to_char (barraasi,'00')));
END IF;
--Fin afiliar ASI
return terminacion;

END;
$function$
