CREATE OR REPLACE FUNCTION public.insertarccfar_validacionitems(fila far_validacionitems)
 RETURNS far_validacionitems
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacionitemscc:= current_timestamp;
    UPDATE sincro.far_validacionitems SET alfabeta= fila.alfabeta, cantidadaprobada= fila.cantidadaprobada, cantidadsolicitada= fila.cantidadsolicitada, codautorizacion= fila.codautorizacion, codbarras= fila.codbarras, codrta= fila.codrta, codtroquel= fila.codtroquel, descripcion= fila.descripcion, far_validacionitemscc= fila.far_validacionitemscc, idcentrovalidacion= fila.idcentrovalidacion, idcentrovalidacionitem= fila.idcentrovalidacionitem, idvalidacion= fila.idvalidacion, idvalidacionitem= fila.idvalidacionitem, importeacargoafiliado= fila.importeacargoafiliado, importeunitario= fila.importeunitario, impotecobertura= fila.impotecobertura, mensajerta= fila.mensajerta, nroitem= fila.nroitem, porcentajecobertura= fila.porcentajecobertura WHERE idcentrovalidacionitem= fila.idcentrovalidacionitem AND idvalidacionitem= fila.idvalidacionitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_validacionitems(alfabeta, cantidadaprobada, cantidadsolicitada, codautorizacion, codbarras, codrta, codtroquel, descripcion, far_validacionitemscc, idcentrovalidacion, idcentrovalidacionitem, idvalidacion, idvalidacionitem, importeacargoafiliado, importeunitario, impotecobertura, mensajerta, nroitem, porcentajecobertura) VALUES (fila.alfabeta, fila.cantidadaprobada, fila.cantidadsolicitada, fila.codautorizacion, fila.codbarras, fila.codrta, fila.codtroquel, fila.descripcion, fila.far_validacionitemscc, fila.idcentrovalidacion, fila.idcentrovalidacionitem, fila.idvalidacion, fila.idvalidacionitem, fila.importeacargoafiliado, fila.importeunitario, fila.impotecobertura, fila.mensajerta, fila.nroitem, fila.porcentajecobertura);
    END IF;
    RETURN fila;
    END;
    $function$
