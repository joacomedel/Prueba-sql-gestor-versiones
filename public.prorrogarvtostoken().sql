CREATE OR REPLACE FUNCTION public.prorrogarvtostoken()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    aux  RECORD;
	 
	resultado boolean;
	 

BEGIN
	resultado = true;
/*
Actualizo los vtos de los tokens de las ordenes
*/

select into aux * from persona_token  where  nullvalue(ptutilizado);

if (FOUND ) then 

     update persona_token 
      SET ptfechavencimiento = (current_timestamp + INTERVAL '181 DAY') 
      where  nullvalue(ptutilizado) AND ptfechavencimiento < current_date  ;
end if;
	return resultado;
END;

$function$
