CREATE OR REPLACE FUNCTION public.devolvernrofactura(centro integer, tipocomprobante integer, tipofactura character varying, nrosucursal integer)
 RETURNS talonario
 LANGUAGE plpgsql
AS $function$declare
      resultado talonario%ROWTYPE;
begin
      select into resultado * from talonario
      --MaLaPi 11/12/2020 Si no me envian el centro, no lo uso en la consulta
      where (talonario.centro=$1 OR $1 = 0 )
            and talonario.tipocomprobante=$2
            and talonario.tipofactura = $3
            and vencimiento >= CURRENT_DATE
             and talonario.nrosucursal =$4
            and sgtenumero <= nrofinal;

--Retorno null como parametro de control para saber si el talonario no esta en condiciones de uso 
if NOT FOUND then
        --return null;
        RAISE EXCEPTION 'No se puede asentar la factura de venta. El motivo puede ser, o que el talonario este vencido, o que se haya llegado a la última factura del talonario (%,%,%,%)',$1,$2,$3,$4;
else
 update talonario set sgtenumero=sgtenumero+1
 where talonario.centro=resultado.centro
       and talonario.tipocomprobante = $2
         and talonario.nrosucursal =$4
       and talonario.tipofactura = $3;
 return resultado;
end if;
end;
$function$
