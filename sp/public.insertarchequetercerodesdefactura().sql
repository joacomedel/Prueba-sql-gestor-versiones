CREATE OR REPLACE FUNCTION public.insertarchequetercerodesdefactura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
       elnuevoreg record;
       elche bigint;

BEGIN
  elnuevoreg = NEW;

  if elnuevoreg.idvalorescaja=47 then --es cheque

     INSERT into cheque(cnumero,cmonto,idbanco)
     VALUES (elnuevoreg.nrocupon::bigint,elnuevoreg.monto,elnuevoreg.autorizacion::bigint);

     elche = currval('cheque_idcheque_seq');

     INSERT into chequetercero(idcheque,idcentrocheque,idfacturacupon,centro,nrofactura,tipocomprobante,tipofactura,nrosucursal)
     VALUES(elche,centro(),elnuevoreg.idfacturacupon,centro(),elnuevoreg.nrofactura,elnuevoreg.tipocomprobante,elnuevoreg.tipofactura,elnuevoreg.nrosucursal);

  end if;

RETURN NEW;
END;
$function$
