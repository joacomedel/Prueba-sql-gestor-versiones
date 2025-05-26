CREATE OR REPLACE FUNCTION public.cambiarestadotituconfechafinosparadebug(character varying, smallint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Verifica que el estado se corresponda con el que deberia tener segun su fechafinos, en caso de no se
un esdo valido, se actualiza al estado valido
*/
DECLARE

    per RECORD;
    fechafin DATE;
    fechafinactivo DATE;
    ndoc alias for $1;
	tipodoc alias for $2;
	pertitular record;

BEGIN
        SELECT INTO per * FROM persona WHERE nrodoc = ndoc AND tipodoc = tipodoc;
        SELECT INTO fechafinactivo  per.fechafinos::date  - 90;
  		fechafin = per.fechafinos;
		if(fechafin < current_date) /*Corresponde asignarle estado pasivo*/
  		then
  		    if(per.barra < 30) then /*Se trata de un benefsosunc*/
               UPDATE benefsosunc SET idestado = 4 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
  		    else /*Se trata de un afilsosunc*/
  		       UPDATE afilsosunc SET idestado = 4 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
  		    end if;
  		 else /*La persona aun se encuentra con cebertura de la Obra Social*/
  			if(fechafinactivo < current_date) /* Ya se le termino la designacion o resolucion, corresponde estado Compensacion de Carencia*/
  				then
     			    if(per.barra < 30) then /*Se trata de un benefsosunc*/
   			           SELECT INTO pertitular * FROM persona
                                              JOIN benefsosunc ON (persona.nrodoc = benefsosunc.nrodoctitu
   			                                  AND persona.tipodoc = benefsosunc.tipodoctitu)
                                              WHERE benefsosunc.nrodoc= per.nrodoc AND benefsosunc.tipodoc = per.tipodoc;
                       IF  (pertitular.barra = 34 OR pertitular.barra = 35 OR pertitular.barra = 36) THEN
                            UPDATE benefsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                       ELSE
                             UPDATE benefsosunc SET idestado = 3 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                       END IF;
                    else /*Se trata de un afilsosunc*/
                         IF (per.barra = 34 OR per.barra = 35 OR per.barra = 36 ) THEN
                              UPDATE afilsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                         ELSE
                             UPDATE afilsosunc SET idestado = 3 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                         END IF;

                    end if;
  		    else /*Aun tiene designacion vigente o resolucion vigente, no se tiene en cuenta el estado Carencia de Servicios */
		         /*Corresponde Activo para el Titular y sus Beneficiarios*/
                    if(per.barra < 30) then /*Se trata de un benefsosunc*/
                       UPDATE benefsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                    else /*Se trata de un afilsosunc*/
                       UPDATE afilsosunc SET idestado = 2 WHERE nrodoc= per.nrodoc AND tipodoc = per.tipodoc;
                    end if;	
            end if;
      end if;
      /*MALAPI*/
  return true;
end;
$function$
