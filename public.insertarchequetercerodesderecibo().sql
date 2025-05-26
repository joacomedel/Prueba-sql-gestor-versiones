CREATE OR REPLACE FUNCTION public.insertarchequetercerodesderecibo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
       elnuevoreg record;
       elche bigint;
       resp boolean;
BEGIN
  elnuevoreg = NEW;

  if elnuevoreg.idvalorescaja=47 then --es cheque

     INSERT into cheque(cnumero,cmonto,idbanco)
     VALUES (elnuevoreg.nrocupon::bigint,elnuevoreg.monto,elnuevoreg.autorizacion::bigint);

     elche = currval('cheque_idcheque_seq');

     INSERT into chequetercero(idcheque,idcentrocheque,idrecibocupon,idcentrorecibocupon)
     VALUES(elche,centro(),elnuevoreg.idrecibocupon,elnuevoreg.idcentrorecibocupon);

     -- VAS 15-11-17 ingreso el estado del cheque
     SELECT INTO resp cambiarestadocheque(elche,centro(),1,'Desde SP insertarchequetercero ');
     -- $1 idcheque $2 idcentrocheque  $3 idchequeestado $4 comentario

  end if;

RETURN NEW;
END;
$function$
