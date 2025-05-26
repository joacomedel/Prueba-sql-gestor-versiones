CREATE OR REPLACE FUNCTION public.arreglarcuil(character varying, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	nrodocumento alias for $1;
	tipodocumento alias for $2;
	elem RECORD;
	inicio character varying;
	numero character varying;
	serie character varying;
	suma integer;
        i integer;
        digito integer;
        
BEGIN
----nrodoc,tipodoc,nrocuilini,nrocuilfin,nrocuildni
select INTO elem * from afilsosunc natural join persona where  nrodoc = nrodocumento AND tipodoc = tipodocumento;

       inicio = CASE WHEN elem.sexo = 'F' THEN '27' ELSE '20' END;
        serie = '5432765432';
	numero = concat(inicio ,  elem.nrodoc);
	suma = 0;
	i = 1;
	while(i <= 10) loop
		suma = suma + substr(numero,i,1)::integer * substr(serie,i,1)::integer;
		i=i+1;
	end loop;

	digito = 11 - mod(suma,11);
	digito = CASE WHEN digito = 11 THEN 0 ELSE digito END;
	digito = CASE WHEN digito = 10 THEN 9 ELSE digito END;

 UPDATE afilsosunc SET nrocuilini = inicio, nrocuildni = nrodoc,nrocuilfin = digito 
	where  nrodoc = nrodocumento AND tipodoc = tipodocumento; 


return digito;
END;
$function$
