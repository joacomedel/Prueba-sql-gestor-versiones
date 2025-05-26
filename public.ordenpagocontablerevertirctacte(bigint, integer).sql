CREATE OR REPLACE FUNCTION public.ordenpagocontablerevertirctacte(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   regopc record;
   restadoopc record; 
   curasiento refcursor;
   regimputa RECORD;
   vopcanulada boolean;
   ximporte double precision;
   xnuevosaldo double precision; 
   xsaldoactual double precision;
BEGIN
vopcanulada = false; 
select into restadoopc * from ordenpagocontableestado WHERE idordenpagocontable=$1 and idcentroordenpagocontable=$2 and nullvalue(opcfechafin) and idordenpagocontableestadotipo=6;
IF FOUND THEN 
   vopcanulada = true;
END IF; 

--KR 05-08-18 me quedo solo con la deuda generada por la OPC
select into regopc * from ctactepagoprestador where idcomprobante=$1*10+$2 AND idcomprobantetipos=40;


if found then

OPEN curasiento FOR
                SELECT *
                FROM ctactedeudapagoprestador
                where idpago = regopc.idpago and idcentropago =regopc.idcentropago;

FETCH curasiento INTO regimputa;
WHILE FOUND LOOP
--Actualizar la deuda
--KR 12-04-18 si la OPC esta anulada, el importeimp se SUMA al saldo de la deuda

-- CS 2018-06-22 el saldo no deberia ser mayor al importe ni menor que 0
        select into ximporte importe from ctactedeudaprestador where  iddeuda = regimputa.iddeuda AND idcentrodeuda = regimputa.idcentrodeuda;
        select into xsaldoactual saldo from ctactedeudaprestador where  iddeuda = regimputa.iddeuda AND idcentrodeuda = regimputa.idcentrodeuda;
        xnuevosaldo = xsaldoactual + case when vopcanulada then regimputa.importeimp else (regimputa.importeimp*-1) end;
        if (xnuevosaldo<0) then xnuevosaldo=0; end if;
        if (xnuevosaldo>ximporte) then xnuevosaldo=ximporte; end if;
------------------------------------------------------------------------
	update ctactedeudaprestador set saldo= xnuevosaldo
	where  iddeuda = regimputa.iddeuda AND idcentrodeuda = regimputa.idcentrodeuda;
	FETCH curasiento INTO regimputa;
END LOOP;
CLOSE curasiento;

--Actualizar la imputacion
	update ctactedeudapagoprestador set importeimp=0
	where  idpago = regopc.idpago and idcentropago =regopc.idcentropago;


--Actualizar el pago
	update ctactepagoprestador set importe=0,saldo=0
	where idpago = regopc.idpago and idcentropago =regopc.idcentropago;
end if;

RETURN 'true';
END;

$function$
