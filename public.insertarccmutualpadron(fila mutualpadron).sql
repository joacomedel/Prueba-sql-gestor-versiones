CREATE OR REPLACE FUNCTION public.insertarccmutualpadron(fila mutualpadron)
 RETURNS mutualpadron
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.mutualpadroncc:= current_timestamp;
    UPDATE sincro.mutualpadron SET nrodoc= fila.nrodoc, mpidafiliado= fila.mpidafiliado, idvalorescajafactura= fila.idvalorescajafactura, mutualpadroncc= fila.mutualpadroncc, mpdenominacion= fila.mpdenominacion, idcentromutualpadron= fila.idcentromutualpadron, idobrasocial= fila.idobrasocial, mpmontomaximo= fila.mpmontomaximo, idmutualpadron= fila.idmutualpadron, tipodoc= fila.tipodoc WHERE idcentromutualpadron= fila.idcentromutualpadron AND idmutualpadron= fila.idmutualpadron AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.mutualpadron(nrodoc, mpidafiliado, idvalorescajafactura, mutualpadroncc, mpdenominacion, idcentromutualpadron, idobrasocial, mpmontomaximo, idmutualpadron, tipodoc) VALUES (fila.nrodoc, fila.mpidafiliado, fila.idvalorescajafactura, fila.mutualpadroncc, fila.mpdenominacion, fila.idcentromutualpadron, fila.idobrasocial, fila.mpmontomaximo, fila.idmutualpadron, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
