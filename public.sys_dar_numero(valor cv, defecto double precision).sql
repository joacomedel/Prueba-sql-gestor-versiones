CREATE OR REPLACE FUNCTION public.sys_dar_numero(valor character varying, defecto double precision)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE
	vvalor double precision;
BEGIN 
   --valor = replace(valor,'%','');
   valor = replace(valor,'�','');
   valor = replace(valor,' ','');
   valor = replace(valor,' ','');
   valor = trim(from valor);
   vvalor =  CASE when (trim(valor) = '' OR nullvalue(valor) ) then defecto    --- VAS 080724 agrego OR nullvalue(valor)  -> valor por defecto
                        when trim(valor) = '-' then defecto
			when trim(valor) ~ '[0-9].%' then '0.01'::float 
			when trim(valor) ~ '[A-Z].*$' then defecto
			when array_length(string_to_array(trim(valor), '$'), 1)  > 1 then trim(replace(replace(replace(replace(valor,'%',''),'$',''),'.',''),',','.'))::float
when array_length(string_to_array(valor, ','), 1)  > 1 AND array_length(string_to_array(valor, '.'), 1)  > 1 then trim(replace(replace(valor,'.',''),',','.'))::float 
when array_length(string_to_array(valor, ','), 1)  > 1 AND array_length(string_to_array(valor, '.'), 1)  = 1 then trim(replace(replace(valor,'.',''),',','.'))::float 
ELSE trim(valor)::float END;
   
	 	
			   
     return vvalor;
END;
$function$
