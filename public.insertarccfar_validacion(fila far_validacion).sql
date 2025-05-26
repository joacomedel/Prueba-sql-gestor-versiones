CREATE OR REPLACE FUNCTION public.insertarccfar_validacion(fila far_validacion)
 RETURNS far_validacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacioncc:= current_timestamp;
    UPDATE sincro.far_validacion SET codaccion= fila.codaccion, codrtageneral= fila.codrtageneral, crednumero= fila.crednumero, desrtageneral= fila.desrtageneral, encrenromatricla= fila.encrenromatricla, encretipomatricula= fila.encretipomatricula, encretipoprescriptor= fila.encretipoprescriptor, far_validacioncc= fila.far_validacioncc, fechareceta= fila.fechareceta, fincodigo= fila.fincodigo, idcentrovalidacion= fila.idcentrovalidacion, idmsj= fila.idmsj, idvalidacion= fila.idvalidacion, iniciotrxfecha= fila.iniciotrxfecha, iniciotrxhora= fila.iniciotrxhora, instcodigo= fila.instcodigo, menrtageneral= fila.menrtageneral, nroreferencia= fila.nroreferencia, plan= fila.plan, prestadorcodigo= fila.prestadorcodigo, prestadorcodparafin= fila.prestadorcodparafin, prestadordireccion= fila.prestadordireccion, retiranrodoc= fila.retiranrodoc, retiranrotelefono= fila.retiranrotelefono, retiratipodoc= fila.retiratipodoc, terminalnumero= fila.terminalnumero, terminaltipo= fila.terminaltipo, tipomsj= fila.tipomsj, tipotratamiento= fila.tipotratamiento, vfecha= fila.vfecha, vnroreceta= fila.vnroreceta WHERE idvalidacion= fila.idvalidacion AND idcentrovalidacion= fila.idcentrovalidacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_validacion(codaccion, codrtageneral, crednumero, desrtageneral, encrenromatricla, encretipomatricula, encretipoprescriptor, far_validacioncc, fechareceta, fincodigo, idcentrovalidacion, idmsj, idvalidacion, iniciotrxfecha, iniciotrxhora, instcodigo, menrtageneral, nroreferencia, plan, prestadorcodigo, prestadorcodparafin, prestadordireccion, retiranrodoc, retiranrotelefono, retiratipodoc, terminalnumero, terminaltipo, tipomsj, tipotratamiento, vfecha, vnroreceta) VALUES (fila.codaccion, fila.codrtageneral, fila.crednumero, fila.desrtageneral, fila.encrenromatricla, fila.encretipomatricula, fila.encretipoprescriptor, fila.far_validacioncc, fila.fechareceta, fila.fincodigo, fila.idcentrovalidacion, fila.idmsj, fila.idvalidacion, fila.iniciotrxfecha, fila.iniciotrxhora, fila.instcodigo, fila.menrtageneral, fila.nroreferencia, fila.plan, fila.prestadorcodigo, fila.prestadorcodparafin, fila.prestadordireccion, fila.retiranrodoc, fila.retiranrotelefono, fila.retiratipodoc, fila.terminalnumero, fila.terminaltipo, fila.tipomsj, fila.tipotratamiento, fila.vfecha, fila.vnroreceta);
    END IF;
    RETURN fila;
    END;
    $function$
