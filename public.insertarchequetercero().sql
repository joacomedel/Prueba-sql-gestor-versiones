CREATE OR REPLACE FUNCTION public.insertarchequetercero()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
       elnuevoreg record;
       elprestador record;
       numerofac varchar;
       rmovimientotipo RECORD;
       resp  RECORD;
       elche bigint;
       esrecibo boolean;
BEGIN
  esrecibo=false;
  elnuevoreg = NEW;

  if elnuevoreg.idvalorescaja=47 then --es cheque

     if not nullvalue(elnuevoreg.idrecibo) then
        esrecibo= true;
     end if;

     INSERT into cheque(cnumero,cmonto,idbanco)
     VALUES (elnuevoreg.nrocupon::bigint,elnuevoreg.monto,elnuevoreg.autorizacion::bigint);

     elche = currval('cheque_idcheque_seq');

     if not esrecibo then
          INSERT into chequetercero(idcheque,idcentrocheque,idfacturacupon,centro,nrofactura,tipocomprobante,tipofactura,nrosucursal)
          VALUES(elche,centro(),elnuevoreg.idfacturacupon,centro(),elnuevoreg.nrofactura,elnuevoreg.tipocomprobante,elnuevoreg.tipofactura,elnuevoreg.nrosucursal);
     else
         INSERT into chequetercero(idcheque,idcentrocheque,idrecibocupon,idcentrorecibocupon)
         VALUES(elche,centro(),elnuevoreg.idrecibocupon,elnuevoreg.idcentrorecibocupon);
     end if;
  end if;

RETURN NEW;
END;
$function$
