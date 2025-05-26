CREATE OR REPLACE FUNCTION public.farmacia_cargarrecetaobserver(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rparam RECORD;
    respuesta character varying; 
    idinformacionobserver integer;


    rreceta record;


  rfiles CURSOR FOR SELECT * FROM tempreceta;
  rinfoobserver CURSOR FOR SELECT * FROM tempdatosinfoobserver;
BEGIN
    respuesta = '';
    EXECUTE sys_dar_filtros($1) INTO rparam;


    
    -- Cargo recetas
    IF(NOT (rfiles IS NULL)) THEN  


    --Marco como ingresados el archivo con la recetas
        INSERT INTO informacioncargarecetaobserver(
                iofechainformacion,
                ioidusuariocarga,
                iofilename
                )
            VALUES (
                to_date(rparam.fechareceta,'YYYYMMDD' ),
                25,
                rparam.nombrearchivo
                );
        idinformacionobserver = currval('informacionobserver_idinformacionobserver_seq');

        open rfiles;
        FETCH rfiles into rreceta;
        WHILE FOUND LOOP
                INSERT INTO recetaobserver (
                                    rofechaingreso,
                                    --fechaproceso,
                                    ronumeronodo,
                                    roopf,
                                    roidfarmacia,
                                    rofarmacia,
                                    rofechaprescripcion ,
                                    rofechaventa,
                                    rofechasolicitud,
                                    rofechaanulacion,
                                    roautorizada,
                                    ronroreceta,
                                    ronroafiliado,
                                    rotipomatricula ,
                                    romatricula,
                                    roimportereceta,
                                    roimporteos,
                                    roimporteafiliado ,
                                    rocodigorechazo ,
                                    romotivorechazo ,
                                    rorenglon ,
                                    rocodigoalfabeta ,
                                    rotroquel ,
                                    rocodbarras ,
                                    rocantidad ,
                                    ropvp ,
                                    roprecioreferencia ,
                                    roimporterenglon ,
                                    roimporteosrenglon ,
                                    roimporteafiliadoRenglon ,
                                    rocodrecrenglon ,
                                    romotRechazoRenglon ,
                                    roidplan ,
                                    roplan,
                                    ronombremedico,
                                    roporcentajecobertura,
                                    romontofijo,
                                    roidcontroldosisporafiliado,
                                    roidcontrolunidadesporafiliado,
                                    rocuit,
                                    idinformacionobserver,
                                    idcentroinformacionobserver)
              VALUES (
                      to_date(rparam.fechareceta,'YYYYMMDD' ),
                      --now(),
                      rreceta.numeronodo,
                      rreceta.opf,
                      rreceta.idfarmacia,
                      rreceta.farmacia,
                      rreceta.fechaprescripcion,
                      rreceta.fechaventa,
                      rreceta.fechasolicitud,
                      rreceta.fechaanulacion,
                      rreceta.autorizada,
                      rreceta.nroreceta,
                      rreceta.nroafiliado,
                      rreceta.tipomatricula ,
                      rreceta.matricula,
                      rreceta.importereceta,
                      rreceta.importeos,
                      rreceta.importeafiliado ,
                      rreceta.codigorechazo ,
                      rreceta.motivorechazo ,
                      rreceta.renglon ,
                      rreceta.codigoalfabeta ,
                      rreceta.troquel ,
                      rreceta.codbarras ,
                      rreceta.cantidad ,
                      rreceta.pvp ,
                      rreceta.precioreferencia ,
                      rreceta.importerenglon ,
                      rreceta.importeosrenglon ,
                      rreceta.importeafiliadoRenglon ,
                      rreceta.codrecrenglon ,
                      rreceta.motRechazoRenglon ,
                      rreceta.idplan ,
                      rreceta.plan,
                      rreceta.nombremedico,
                      rreceta.porcentajecobertura,
                      rreceta.montofijo,
                      rreceta.idcontroldosisporafiliado,
                      rreceta.idcontrolunidadesporafiliado,
                      rreceta.cuit,
                      idinformacionobserver,
                      centro()
                      );        
                FETCH rfiles into rreceta;
        END LOOP;
        CLOSE rfiles;

        
    END IF;


     respuesta = 'todook';
      
    
return respuesta;
END;
$function$
