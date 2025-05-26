CREATE OR REPLACE FUNCTION public.farmacia_cargarcaratulaobserver(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    rparam RECORD;
    respuesta character varying; 
    idinformacionobservervar integer;

    rcabecera record;

    cfiles CURSOR FOR SELECT * FROM tempcaratula;
    rinfoobserver CURSOR FOR SELECT * FROM tempdatosinfoobserver;

BEGIN
    respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;

    -- Cargo caratulas
    IF(NOT (cfiles IS NULL)) THEN  

    --Marco como ingresados el archivo con la caratula
        INSERT INTO informacioncargarcaratulaobserver(
            iofechainformacion,
            ioidusuariocarga,
            iofilename
        )
        VALUES (
            to_date(rparam.fechacaratula,'YYYYMMDD' ),
            25,
            rparam.nombrearchivo
        );
        idinformacionobservervar = currval('informacioncarobserver_idinformacionobserver_seq');
        -- SELECT last_value INTO idinformacionobservervar FROM informacioncarobserver_idinformacionobserver_seq;

        open cfiles;
        FETCH cfiles into rcabecera;
        WHILE FOUND LOOP
            INSERT INTO caratulaobserver (
                coopf,
                coidfarmacia,
                cofarmacia,
                coidconvenio,
                coconvenio,
                coidplan,
                coplan,
                cofechacierre,
                cocanttotalrecetas,
                coimportetotalrecetas,
                coimportetotalacargoos,
                coimportetotalacargoafil,
                conrocaratula,
                cocuit,
                idinformacionobserver,
                idcentroinformacionobserver)
            VALUES (
                rcabecera.opf,
                rcabecera.idfarmacia,
                rcabecera.farmacia,
                rcabecera.idconvenio,
                rcabecera.convenio,
                rcabecera.idplan,
                rcabecera.plan,
                rcabecera.fechacierre,
                rcabecera.canttotalrecetas,
                rcabecera.importetotalrecetas,
                rcabecera.importetotalacargoos,
                rcabecera.importetotalacargoafil,
                rcabecera.nrocaratula,
                rcabecera.cuit,
                idinformacionobservervar,
                centro());
                FETCH cfiles into rcabecera;
        END LOOP;
        CLOSE cfiles;

    END IF;


    respuesta = 'todook';

return respuesta;
END;

$function$
