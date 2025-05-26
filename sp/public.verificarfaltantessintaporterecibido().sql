CREATE OR REPLACE FUNCTION public.verificarfaltantessintaporterecibido()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

alta refcursor;
elem RECORD;
resultado boolean;
contador int;
mes int;
anio int;
numeroinforme int;
fechafinultimoaporte date;

BEGIN

DELETE FROM tsinaporte;

INSERT INTO tsinaporte
 SELECT DISTINCT nrodoc,barra,tipodoc,idestado FROM (
        (SELECT * FROM
               (SELECT tipodoc, nrodoc, barra, idestado FROM persona
                                                        NATURAL JOIN afilsosunc
                                                        WHERE idestado <> 4)  as titu
                 )
         ) AS uniDatos
  WHERE barra < 100;

resultado = true;

mes = date_part('month', current_date);
anio = date_part('year', current_date);

numeroinforme = anio * 100 + mes;

OPEN alta FOR SELECT * FROM tsinaporte
              ORDER BY tsinaporte.nrodoc,tsinaporte.tipodoc;
FETCH alta INTO elem;
WHILE  found LOOP

IF  (elem.idestado = 1) THEN
	INSERT INTO infaportesfaltantes VALUES('5',current_date,anio,mes,elem.nrodoc,elem.barra,elem.tipodoc,numeroinforme);
END IF;

IF  (elem.idestado = 2) THEN
	INSERT INTO infaportesfaltantes VALUES('5',current_date,anio,mes,elem.nrodoc,elem.barra,elem.tipodoc,numeroinforme);
--	SELECT INTO contador contcarencia FROM persona WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
--	contador = contador + 1;
--	UPDATE persona SET contcarencia =  contador WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
END IF;

IF  (elem.idestado = 3) THEN
--	SELECT INTO contador contcarencia FROM persona WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;	
--	UPDATE persona SET contcarencia =  contador WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
	INSERT INTO infaportesfaltantes VALUES('6',current_date,anio,mes,elem.nrodoc,elem.barra,elem.tipodoc,numeroinforme);
END IF;
SELECT INTO fechafinultimoaporte * FROM ultimoaporterecibido(elem.nrodoc,elem.tipodoc);
IF (not nullvalue(fechafinultimoaporte)) THEN
  IF (elem.barra = 35 OR elem.barra = 36) THEN
    IF(fechafinultimoaporte <= (CURRENT_DATE - 34)) THEN
       UPDATE persona SET fechafinos=fechafinultimoaporte + 30 WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
     END IF;
  ELSE
   IF(fechafinultimoaporte <= (CURRENT_DATE - 34)) THEN
      UPDATE persona SET fechafinos=fechafinultimoaporte + 90 WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
     END IF;

   END IF;

ELSE
    UPDATE persona SET fechafinos=fechainios + 90 WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
END IF;		
fetch alta into elem;
END LOOP;
CLOSE alta;
return resultado;
END;
$function$
