CREATE OR REPLACE FUNCTION public.afiliaciones_asignarcentroregional()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* MaLapi 30-08-2022 Proceso que recorre las personas ACTIVAS y asigna un centro regional segun su consumo. 
*/
DECLARE
--cursores
      cursortempaf refcursor;
--registros
      regafil RECORD;
      datoPersona RECORD;
begin

/* Busco los datos de la persona*/
OPEN cursortempaf FOR select * from persona LEFT JOIN personacentroregional  AS pc USING(nrodoc)  
    WHERE fechafinos >= current_date AND (nullvalue(pc.nrodoc) OR (pc.idcentroregional = 98 AND nullvalue(pcfechafin)) );
FETCH cursortempaf INTO regafil;
  WHILE FOUND LOOP
   SELECT INTO datoPersona count(nroorden) as cantidad,centro 
   FROM consumo 
   NATURAL JOIN  orden 
   WHERE /*fechaemision >= current_date - 730::integer AND*/ nrodoc = regafil.nrodoc 
   group by centro ORDER BY count(nroorden) LIMIT 1;
   IF FOUND THEN
       UPDATE personacentroregional SET pcfechafin = now() WHERE nrodoc = regafil.nrodoc AND nullvalue(pcfechafin);
		INSERT INTO  personacentroregional(nrodoc, tipodoc, idcentroregional,pcfechafin) 
		VALUES(regafil.nrodoc,regafil.tipodoc,datoPersona.centro,null);
	ELSE
	--MaLaPi 30-08-2022 Por defecto, si la persona no consumio, se le asigna el centro 98
               IF nullvalue(regafil.idcentroregional) THEN
		 INSERT INTO  personacentroregional(nrodoc, tipodoc, idcentroregional,pcfechafin) 
		VALUES(regafil.nrodoc,regafil.tipodoc,98,null);
               END IF;
	END IF;
	FETCH cursortempaf INTO regafil;
	  END LOOP;
CLOSE cursortempaf;

--SELECT max(cantidad) as cantidad,centro,nrodoc,tipodoc  FROM (
--SELECT count(nroorden) as cantidad,centro,nrodoc,tipodoc 
--   FROM consumo 
--   NATURAL JOIN persona
--   NATURAL JOIN  orden 
--   WHERE fechaemision >= current_date - 730::integer 
--      AND fechafinos >= current_date AND  not anulado
--   group by nrodoc,tipodoc ,centro
--) as ultimosconsumo
--group by nrodoc,tipodoc,centro ;




return true;
end;
$function$
