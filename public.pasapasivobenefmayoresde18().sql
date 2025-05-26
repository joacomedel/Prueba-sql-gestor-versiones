CREATE OR REPLACE FUNCTION public.pasapasivobenefmayoresde18()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

rec RECORD;
reg RECORD;
datop RECORD;

fechaFinAnio date;
fechah	VARCHAR;
fechap	DATE;

BEGIN
	fechaFinAnio = concat(EXTRACT(year FROM current_timestamp) , '-12-31');

	fechah = CURRENT_DATE;
	
	FOR rec IN SELECT *  FROM benefsosunc
			NATURAL JOIN persona
			WHERE  18 <= extract(year from age(to_date(concat(EXTRACT(year FROM current_timestamp) , '-12-31'),'yyyy-MM-dd'),fechanac))
				
				AND idestado <> 4
				AND persona.barra > 1
				AND persona.barra < 21

			LOOP
			
                SELECT  fechavto,nrodoc INTO datop 	FROM prorroga  WHERE prorroga.tipodoc = rec.tipodoc
                                        AND prorroga.nrodoc = rec.nrodoc AND prorroga.fechavto > CURRENT_DATE;
				
				IF FOUND THEN
				/*Si el Beneficiario tiene prorroga hay que verificar la fecha de vto de la prorroga*/
    				fechap = datop.fechavto;
				    IF fechap < CURRENT_DATE THEN
					   UPDATE persona SET fechafinos = to_date(concat(EXTRACT(year FROM current_timestamp) , '-04-30'),'yyyy-MM-dd')
                                      WHERE persona.tipodoc = rec.tipodoc AND persona.nrodoc  = rec.nrodoc;
                     /*  UPDATE benefsosunc SET idestado = 4 WHERE benefsosunc.tipodoc = rec.tipodoc AND
                                                    	       benefsosunc.nrodoc  = rec.nrodoc;*/
             	    ELSE
             	    /*Si tiene una prorroga debe tener fecha fin os el vto de la prorroga*/
             	        UPDATE persona SET fechafinos = fechap
                                      WHERE persona.tipodoc = rec.tipodoc AND persona.nrodoc  = rec.nrodoc;
                    END IF;
                 /*Si el Beneficiario no tiene proroga vigente hay que poner al afiliado en pasivo*/
                 ELSE
                     UPDATE persona SET fechafinos = to_date(concat(EXTRACT(year FROM current_timestamp) , '-04-30'),'yyyy-MM-dd')
                                     WHERE persona.tipodoc = rec.tipodoc AND persona.nrodoc  = rec.nrodoc;
                     /*UPDATE benefsosunc SET idestado = 4 WHERE benefsosunc.tipodoc = rec.tipodoc AND
                                                    	       benefsosunc.nrodoc  = rec.nrodoc;*/
                END if;
			END LOOP ;

   RETURN 'true';
END;
$function$
