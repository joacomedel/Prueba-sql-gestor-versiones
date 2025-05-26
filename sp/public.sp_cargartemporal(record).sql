CREATE OR REPLACE FUNCTION public.sp_cargartemporal(record)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

        --RECORD


        rparam RECORD;
        rcobertura RECORD;
       

BEGIN


    -- OBTENGO PARAMETROS 
    --EXECUTE sys_dar_filtros($1) INTO rparam; 

    rcobertura=$1;



    INSERT INTO tfar_coberturas ( 
            idiva ,
            lstock ,
            precio ,
            idrubro ,
            porccob ,
            porciva ,
            troquel ,
            cantidadsolicitada ,
            cantidadaprobada,
            astockmax ,
            astockmin ,
            monodroga ,
            montofijo ,
            prioridad ,
            adescuento ,
            detallecob ,
            idarticulo ,
            acomentario ,
            idmonodroga ,
            laboratorio ,
            acodigobarra ,
            adescripcion ,
            idobrasocial ,
            mnroregistro ,
            presentacion ,
            rdescripcion ,
            idlaboratorio ,
            pcdescripcion ,
            acodigointerno ,
            articulodetalle ,
            codautorizacion ,
            idplancobertura ,
            idcentroarticulo ) 
    VALUES (
            rcobertura.idiva ,
            rcobertura.lstock ,
            rcobertura.precio ,
            rcobertura.idrubro ,
            rcobertura.porccob ,
            rcobertura.porciva ,
            rcobertura.troquel ,
            rcobertura.cantidadvendida,
            rcobertura.cantidadaprobada ,
            rcobertura.astockmax ,
            rcobertura.astockmin ,
            rcobertura.monodroga ,
            rcobertura.montofijo ,
            rcobertura.prioridad ,
            rcobertura.adescuento ,
            rcobertura.detallecob ,
            rcobertura.idarticulo ,
            rcobertura.acomentario ,
            rcobertura.idmonodroga ,
            rcobertura.laboratorio ,
            rcobertura.acodigobarra ,
            rcobertura.adescripcion ,
            rcobertura.idobrasocial ,
            rcobertura.mnroregistro ,
            rcobertura.presentacion ,
            rcobertura.rdescripcion ,
            rcobertura.idlaboratorio ,
            rcobertura.pcdescripcion ,
            rcobertura.acodigointerno ,
            rcobertura.articulodetalle ,
            rcobertura.codautorizacion ,
            rcobertura.idplancobertura ,
            rcobertura.idcentroarticulo
    );
    

return true;

end;
$function$
