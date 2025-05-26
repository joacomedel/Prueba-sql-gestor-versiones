CREATE OR REPLACE FUNCTION public.montoporvalorcaja(bigint, character varying, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$declare
  valor  double precision;
begin

select into valor  case when nullvalue(sum(montofactura.monto)) then 0 
	else  sum(montofactura.monto)
	end as valor1 

  from (	
	select  case WHEN not nullvalue(anulada) THEN 0
                  when  tipofactura = 'NC'  then (-1)*(monto)
	             
                 else monto  end as monto
	from facturaventacupon 
       JOIN facturaventa  USING(nrofactura,nrosucursal,tipofactura,tipocomprobante)
    -- AGREGA VIVI 02/03/2014 para saber si la factura esta anulada
   -- MLP 14-12-2015 Quito el natural y coloco un JOIN, para que no tome el centro como campo compartido
	where   nrofactura = $1 
		and tipofactura=$2  
		and  tipocomprobante = $3 
		and nrosucursal=$4
        and idvalorescaja=$5
  )  as montofactura;
  

return valor;
end;
$function$
