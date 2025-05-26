CREATE OR REPLACE FUNCTION public.insertarccasientoimputacion(fila asientoimputacion)
 RETURNS asientoimputacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientoimputacioncc:= current_timestamp;
    UPDATE sincro.asientoimputacion SET afpdescripcion= fila.afpdescripcion, asientoimputacioncc= fila.asientoimputacioncc, idasientocancela= fila.idasientocancela, idasientocontable= fila.idasientocontable, idasientoimputacion= fila.idasientoimputacion, idasientoimputacioncancela= fila.idasientoimputacioncancela, idcentroregional= fila.idcentroregional, idcuentacontabletipos= fila.idcuentacontabletipos, idformapagotipos= fila.idformapagotipos, montodebe= fila.montodebe, montohaber= fila.montohaber WHERE idasientocontable= fila.idasientocontable AND idasientoimputacion= fila.idasientoimputacion AND idcentroregional= fila.idcentroregional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.asientoimputacion(afpdescripcion, asientoimputacioncc, idasientocancela, idasientocontable, idasientoimputacion, idasientoimputacioncancela, idcentroregional, idcuentacontabletipos, idformapagotipos, montodebe, montohaber) VALUES (fila.afpdescripcion, fila.asientoimputacioncc, fila.idasientocancela, fila.idasientocontable, fila.idasientoimputacion, fila.idasientoimputacioncancela, fila.idcentroregional, fila.idcuentacontabletipos, fila.idformapagotipos, fila.montodebe, fila.montohaber);
    END IF;
    RETURN fila;
    END;
    $function$
