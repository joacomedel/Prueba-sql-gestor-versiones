CREATE OR REPLACE FUNCTION public.actualizarlafechadefinosbeneftemporal()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
aux boolean;
pers RECORD;
recprorroga RECORD;
fechafinpadre DATE;
fechacumple DATE;
edad INTEGER;
fechafin DATE;
auxcumple DATE;
cumpleactual DATE;		
cumplesig DATE;

BEGIN
SELECT INTO pers * FROM persona WHERE nrodoc='32528240' /*NEW.nrodoc*/ and tipodoc=1 /*NEW.tipodoc;*/;
SELECT INTO fechafinpadre persona.fechafinos FROM persona
                                          JOIN benefsosunc ON benefsosunc.nrodoctitu = persona.nrodoc
                                                           AND benefsosunc.tipodoctitu = persona.tipodoc
                                          WHERE benefsosunc.nrodoc = pers.nrodoc
                                               AND benefsosunc.tipodoc = pers.tipodoc;
        
             edad = extract(year FROM age(

             to_date(to_char( concat ( extract(year FROM CURRENT_DATE),'9999'),'-12-31'),'YYYY-MM-DD'),pers.fechanac));	
		     cumplesig    = to_date(concat ( to_char(extract(year from current_date)+1,'9999')
                                    ,'-',
                                    to_char(extract(month from to_date(pers.fechanac,'YYYY-MM-DD')),'99')
                                    ,'-',
                                    to_char(extract(day from to_date(pers.fechanac,'YYYY-MM-DD')),'99')
                                    ),'YYYY-MM-DD');
             --raise notice 'Ya seteamos las variables importantes';	
             IF edad < 17 THEN
                UPDATE persona SET fechafinos = fechafinpadre WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
            	--raise notice 'La fechafinOS es la del padre.';	
      	     END IF;
      	     IF edad = 17 THEN
      	        SELECT INTO recprorroga * FROM (SELECT MAX(prorroga.idprorr) as idprorr FROM prorroga
                                              WHERE nrodoc = pers.nrodoc AND prorroga.tipodoc = pers.tipodoc) as ultimaprorroga
                                              NATURAL JOIN prorroga
                                              WHERE prorroga.tipoprorr = 18;
                SELECT INTO fechafin * FROM minimadetresfechas(recprorroga.fechavto,fechafinpadre,cumplesig);
                UPDATE persona SET fechafinos = fechafin WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
            	--raise notice 'La fechafinOS es la menor entre la prorroga, el padre y el cumpleaños.';	
           	  END IF;
           	  IF edad > 17  AND edad < 20 THEN
      	        SELECT INTO recprorroga * FROM (SELECT MAX(prorroga.idprorr) as idprorr FROM prorroga
                                              WHERE nrodoc = pers.nrodoc AND prorroga.tipodoc = pers.tipodoc) as ultimaprorroga
                                              NATURAL JOIN prorroga
                                              WHERE prorroga.tipoprorr = 18;
                 IF NOT FOUND THEN
                    UPDATE persona SET fechafinos = CURRENT_DATE - 1 WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
                    --raise notice 'La fechafinOS es ayer no tiene una prorroga ingresada.';	
                  ELSE
                   SELECT INTO fechafin * FROM minimadetresfechas(recprorroga.fechavto,fechafinpadre,NULL);
                   UPDATE persona SET fechafinos = fechafin WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
            	  --raise notice 'La fechafinOS es la menor entre la prorroga y el padre.';	
            	  END IF;
           	  END IF;
           	  IF edad = 20 THEN
      	        SELECT INTO recprorroga * FROM (SELECT MAX(prorroga.idprorr) as idprorr FROM prorroga
                                              WHERE nrodoc = pers.nrodoc AND prorroga.tipodoc = pers.tipodoc) as ultimaprorroga
                                              NATURAL JOIN prorroga
                                              WHERE prorroga.tipoprorr = 18 OR prorroga.tipoprorr = 21;
                SELECT INTO fechafin * FROM minimadetresfechas(recprorroga.fechavto,fechafinpadre,cumplesig);
                UPDATE persona SET fechafinos = fechafin WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
            	--raise notice 'La fechafinOS es la menor entre la prorroga de 18 o 21, el padre y el cumpleaños.';	
           	  END IF;
           	  IF edad > 20  AND edad < 25 THEN
      	        SELECT INTO recprorroga * FROM (SELECT MAX(prorroga.idprorr) as idprorr FROM prorroga
                                              WHERE nrodoc = pers.nrodoc AND prorroga.tipodoc = pers.tipodoc) as ultimaprorroga
                                              NATURAL JOIN prorroga
                                              WHERE prorroga.tipoprorr = 21;
               IF NOT FOUND THEN
                  UPDATE persona SET fechafinos = CURRENT_DATE - 1 WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
            	  --raise notice 'La fechafinOS es ayer no tiene una prorroga ingresada.';	
               ELSE
                SELECT INTO fechafin * FROM minimadetresfechas(recprorroga.fechavto,fechafinpadre,NULL);
                UPDATE persona SET fechafinos = fechafin WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
            	--raise notice 'La fechafinOS es la menor entre la prorroga de 21 y el padre.';	
           	   END IF;
           	  END IF;
           	  IF edad = 25 THEN
      	        UPDATE persona SET fechafinos = cumplesig WHERE nrodoc=pers.nrodoc and tipodoc=pers.tipodoc;
            	--raise notice 'La fechafinOS es el cumpleaños 26.';	
           	  END IF;
           	  
return TRUE;
	
END;
$function$
