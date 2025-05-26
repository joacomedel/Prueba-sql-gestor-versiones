CREATE OR REPLACE FUNCTION public.buscarcarnet(integer, integer, integer, integer, integer, integer, integer, integer, integer, character varying, bigint, date, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  
resultado boolean;

BEGIN
--DELETE FROM tcupones WHERE usuario = $10;
if $1 = 2
	then
		SELECT INTO resultado * FROM buscarsolobenef($10);
	else
		if $2 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$2,$10,$11,$12,$13);
		end if;
		if $3 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$3,$10,$11,$12,$13);
		end if;
		if $4 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$4,$10,$11,$12,$13);
		end if;
		if $5 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$5,$10,$11,$12,$13);
		end if;
		if $6 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$6,$10,$11,$12,$13);
		end if;
		if $7 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$7,$10,$11,$12,$13);
		end if;
		if $8 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$8,$10,$11,$12,$13);
		end if;
		if $9 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$9,$10,$11,$12,$13);
		end if;
end if;

   RETURN resultado;
END;
$function$
