CREATE OR REPLACE FUNCTION public.insertarccpersonajuridicabis(fila personajuridicabis)
 RETURNS personajuridicabis
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.personajuridicabiscc:= current_timestamp;
    UPDATE sincro.personajuridicabis SET barra= fila.barra, cuitfin= fila.cuitfin, cuitini= fila.cuitini, cuitmedio= fila.cuitmedio, denominacion= fila.denominacion, nrocliente= fila.nrocliente, personajuridicabiscc= fila.personajuridicabiscc WHERE barra= fila.barra AND nrocliente= fila.nrocliente AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.personajuridicabis(barra, cuitfin, cuitini, cuitmedio, denominacion, nrocliente, personajuridicabiscc) VALUES (fila.barra, fila.cuitfin, fila.cuitini, fila.cuitmedio, fila.denominacion, fila.nrocliente, fila.personajuridicabiscc);
    END IF;
    RETURN fila;
    END;
    $function$
