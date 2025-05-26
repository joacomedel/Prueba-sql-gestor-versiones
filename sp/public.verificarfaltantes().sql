CREATE OR REPLACE FUNCTION public.verificarfaltantes()
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

BEGIN

DELETE FROM tsinaporte;

INSERT INTO tsinaporte
 SELECT DISTINCT nrodoc,barra,tipodoc,idestado,usuario FROM (
        (SELECT * FROM
               /*Se excluye del analisis a los Jubilados y Pensionados*/
               (SELECT tipodoc, nrodoc, barra, idestado FROM persona
                                                        NATURAL JOIN afilsosunc
                                                        WHERE persona.barra < 35 AND idestado <> 4)  as titu
                 LEFT JOIN taporterecibido USING (nrodoc,barra)
                WHERE usuario isnull)
                UNION
        (SELECT * FROM
                (SELECT tipodoc, nrodoc, barra, idestado FROM persona
                                                         NATURAL JOIN benefsosunc
                                                         WHERE idestado <> 4) as bene
                LEFT JOIN taporterecibido USING (nrodoc,barra)
                WHERE usuario isnull)
        ) AS uniDatos;

resultado = true;

mes = date_part('month', current_date);
anio = date_part('year', current_date);

numeroinforme = anio * 100 + mes;

OPEN alta FOR SELECT * FROM tsinaporte ORDER BY tsinaporte.nrodoc,tsinaporte.tipodoc;
FETCH alta INTO elem;
WHILE  found LOOP

IF  (elem.idestado = 1) THEN UPDATE persona SET fechafinos=current_date - 1 WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
	INSERT INTO infaportesfaltantes VALUES('5',current_date,anio,mes,elem.nrodoc,elem.barra,elem.tipodoc,numeroinforme);
END IF;

IF  (elem.idestado = 2) THEN UPDATE persona SET fechafinos=current_date + 89 WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
	INSERT INTO infaportesfaltantes VALUES('5',current_date,anio,mes,elem.nrodoc,elem.barra,elem.tipodoc,numeroinforme);
	SELECT INTO contador contcarencia FROM persona WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
	contador = contador + 1;
	UPDATE persona SET contcarencia =  contador WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
END IF;

IF  (elem.idestado = 3) THEN
	SELECT INTO contador contcarencia FROM persona WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;	
	IF (contador >= 4) THEN
		UPDATE persona SET fechafinos=current_date - 1 WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
		contador=0;
	ELSE contador = contador + 1;
	END IF;
	UPDATE persona SET contcarencia =  contador WHERE nrodoc=elem.nrodoc AND  tipodoc=elem.tipodoc;
	INSERT INTO infaportesfaltantes VALUES('6',current_date,anio,mes,elem.nrodoc,elem.barra,elem.tipodoc,numeroinforme);
END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;
return resultado;
END;
$function$
