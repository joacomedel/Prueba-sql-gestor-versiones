CREATE OR REPLACE FUNCTION public.eliminarccfar_articulocontrolvto(fila far_articulocontrolvto)
 RETURNS far_articulocontrolvto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_articulocontrolvtocc:= current_timestamp;
    delete from sincro.far_articulocontrolvto WHERE idarticulo= fila.idarticulo AND idcentroarticulo= fila.idcentroarticulo AND idprecargastockajusteitem= fila.idprecargastockajusteitem AND idcentroprecargastockajusteitem= fila.idcentroprecargastockajusteitem AND TRUE;
    RETURN fila;
    END;
    $function$
