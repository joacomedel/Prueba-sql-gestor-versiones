CREATE OR REPLACE FUNCTION public.asentarnotacreditoorden()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE

cursornota CURSOR FOR
              SELECT *
              FROM ttnotacredito;
/*
nroorden bigint
centro INTEGER
totalnotacredito DOUBLE PRECISION NOT NULL
importeenletras varchar
*/

losItems CURSOR FOR
                 SELECT *
                        FROM ttitemsnotacredito;
unItem RECORD;
dato RECORD;
resp bigint;
nronota bigint;
imputacion varchar;
total double precision;

BEGIN
    resp = 0;
    total = 0;
    --imputacion='Devolución del coseguro de practicas valorizadas mediante Orden N°: ';
    open cursornota;
    fetch cursornota into dato;
    imputacion = concat(to_char(dato.centro,'00'),'-',to_char(dato.nroorden,'00000000'));
    insert into notacredito(importe,fechaemision,centro,nroorden,importeenletras,imputacionnotacredito)
           values(dato.totalnotacredito,current_date,dato.centro,dato.nroorden,dato.importeenletras,imputacion);
    nronota = currval('"public"."notacredito_nronotacredito_seq"');
    OPEN losItems;
    fetch losItems into unItem;
    while found loop
          insert into itemsnotacredito
                 values(unItem.iditem,nronota,dato.centro);
          fetch losItems into unItem;
    end loop;
    close losItems;
    close cursornota;
    return nronota;	
END;
$function$
