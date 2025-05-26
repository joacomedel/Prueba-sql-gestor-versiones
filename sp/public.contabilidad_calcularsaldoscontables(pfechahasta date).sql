CREATE OR REPLACE FUNCTION public.contabilidad_calcularsaldoscontables(pfechahasta date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$ 

DECLARE
	xnrocuentac varchar;

BEGIN
        delete from contabilidad_cuentasconsaldo;
	SELECT nrocuentac into xnrocuentac FROM contabilidad_cuentasconsaldo WHERE  ccsfechahasta=pfechahasta;
	if not found then
		
		insert into contabilidad_cuentasconsaldo(nrocuentac,ccssaldodebe,ccssaldohaber,ccsfechahasta)
		(

SELECT 
nrocuentac,
case when nullvalue(D) then 0 else D end,
case when nullvalue(H) then 0 else H end,
pfechahasta as pfechahasta
FROM (


		select 	c.nrocuentac,
			--case when nullvalue(contabilidad_saldocontable(c.nrocuentac,'D',pfechahasta)) then 0 else contabilidad_saldocontable(c.nrocuentac,'D',pfechahasta) end,
			--case when nullvalue(contabilidad_saldocontable(c.nrocuentac,'H',pfechahasta)) then 0 else contabilidad_saldocontable(c.nrocuentac,'H',pfechahasta) end,
                         contabilidad_saldocontable(c.nrocuentac,'D','2020-01-01') as D,
                         contabilidad_saldocontable(c.nrocuentac,'H','2020-01-01') as H

			--pfechahasta
		from cuentascontables c natural join multivac.mapeocuentascontables m
) as t
		);
	end if;

RETURN true;
END;
$function$
