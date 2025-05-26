CREATE OR REPLACE FUNCTION public.buscarcupones(integer, integer, integer, integer, integer, integer, integer, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
  
resultado boolean;

BEGIN
DELETE FROM tcupones WHERE usurio = $10 ;
if $1 = 2
	then
		SELECT INTO resultado * FROM buscarsolocuponesbenef($10);
	else
		if $2 > 0
			then
				SELECT INTO resultado * FROM buscarcuponespedidos($1,$2,$10);
		end if;
		if $3 > 0
			then
				SELECT INTO resultado * FROM buscarcuponespedidos($1,$3,$10);
		end if;
		if $4 > 0
			then
				SELECT INTO resultado * FROM buscarcuponespedidos($1,$4,$10);
		end if;
		if $5 > 0
			then
				SELECT INTO resultado * FROM buscarcuponespedidos($1,$5,$10);
		end if;
		if $6 > 0
			then
				SELECT INTO resultado * FROM buscarcuponespedidos($1,$6,$10);
		end if;
		if $7 > 0
			then
				SELECT INTO resultado * FROM buscarcuponespedidos($1,$7,$10);
		end if;
		if $8 > 0
			then
				SELECT INTO resultado * FROM buscarcuponespedidos($1,$8,$10);
		end if;
		if $9 > 0
			then
				SELECT INTO resultado * FROM buscarcarnetpedidos($1,$9,$10);
		end if;
end if;

   RETURN resultado;
END;
$function$
