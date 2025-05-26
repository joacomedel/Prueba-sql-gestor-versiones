CREATE OR REPLACE FUNCTION public.actulizarestadopersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    per RECORD; 
    fechafin DATE;    
    fechaini DATE;
BEGIN
  SELECT INTO per * FROM persona WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
  if FOUND
  	then 
  		fechafin = NEW.fechafinlab + INTEGER '90';
  		fechaini = NEW.fechainilab + INTEGER '90';
  		UPDATE persona SET fechafinos = fechafin WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
		UPDATE persona SET fechafinos = fechafin WHERE nrodoc IN (SELECT nrodoc FROM benefsosunc WHERE nrodoctitu= NEW.nrodoc AND tipodoctitu =NEW.tipodoc);
  		if (per.fechafinos < current_date)
  			then
  				if(fechafin < current_date)
  					then
  					   UPDATE afilsosunc SET idestado = 4 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
  					else
  						if(NEW.fechafinlab < current_date)
  							then
  								UPDATE afilsosunc SET idestado = 3 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
  							else 
  								if(fechaini < current_date)
  									then
  										-- modificado 23-02-2007 UPDATE afilsosunc SET idestado = 1 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
										UPDATE afilsosunc SET idestado = 2 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
  									else
  									  	-- modificado 23-02-2007 UPDATE afilsosunc SET idestado = 2 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
										UPDATE afilsosunc SET idestado = 1 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
  								end if;
  						end if;
  				end if;
  			else
  				if(fechafin < current_date)
  					then
  					 	UPDATE afilsosunc SET idestado = 4 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
  					else
  						if (NEW.fechafinlab > current_date)
  							then
  								UPDATE afilsosunc SET idestado = 2 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
  							else
  								UPDATE afilsosunc SET idestado = 3 WHERE nrodoc= NEW.nrodoc AND tipodoc =NEW.tipodoc;
  						end if;
  				end if;
  		end if;
    end if;
  
  return NEW;
  END;
$function$
