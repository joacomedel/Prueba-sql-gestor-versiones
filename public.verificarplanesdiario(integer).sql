CREATE OR REPLACE FUNCTION public.verificarplanesdiario(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    	rplanes refcursor;
	verifica boolean;
        person record;
         
    

BEGIN
verifica=false;
	OPEN rplanes FOR select * from plancobpersona  natural join persona as p 
			where idplancobertura=76
			and nullvalue(pcpfechafin)
			and extract(year FROM age(CURRENT_DATE,p.fechanac))>18
			and fechafinos>='2018-06-01';
	FETCH rplanes into person;
	WHILE  found LOOP
	
	FETCH rplanes into person;
	END LOOP;
	close rplanes;
	return resultado;
END;
$function$
