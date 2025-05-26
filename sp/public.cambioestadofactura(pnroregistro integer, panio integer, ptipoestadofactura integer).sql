CREATE OR REPLACE FUNCTION public.cambioestadofactura(pnroregistro integer, panio integer, ptipoestadofactura integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
    ctemporal refcursor;
    regtemp RECORD;
    idMultivac bigint;
    pnroregistro alias for $1;
    panio alias for $2;
    ptipoestadofactura alias for $3;
    udp boolean;
    obs varchar;

BEGIN
    OPEN ctemporal FOR
         SELECT idrecepcion,idcentroregional
         FROM reclibrofact where numeroregistro=pnroregistro and anio=panio;
         
    FETCH ctemporal INTO regtemp;
    if found then
       if ptipoestadofactura=5 THEN --Rechazada
          obs = 'Eliminado desde Mesa de entradas';

--CS 2017-02-09 No corresponde hacer nada con mapeocompcompras aca
/*
           select idcomprobantemultivac INTO idMultivac
           from mapeocompcompras
           where idrecepcion=regtemp.idrecepcion and idcentroregional=regtemp.idcentroregional;
           
           IF nullvalue(idMultivac) THEN
              udp = false;
           ELSE
               udp = true;
           END IF;
           
           update mapeocompcompras set tipomov='D',update=udp,fechaupdate=CURRENT_TIMESTAMP
           where idrecepcion=regtemp.idrecepcion and idcentroregional=regtemp.idcentroregional;
*/           
       end if;
       
       insert into festados (nroregistro,anio,tipoestadofactura,fechacambio,observacion)
              values (pnroregistro,panio,ptipoestadofactura,current_date,obs);

    END if;
CLOSE ctemporal;

RETURN true;
END;
$function$
