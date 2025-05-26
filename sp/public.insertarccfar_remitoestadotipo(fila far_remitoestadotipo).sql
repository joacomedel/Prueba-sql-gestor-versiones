CREATE OR REPLACE FUNCTION public.insertarccfar_remitoestadotipo(fila far_remitoestadotipo)
 RETURNS far_remitoestadotipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitoestadotipocc:= current_timestamp;
    UPDATE sincro.far_remitoestadotipo SET descripcionremitoestadotipo= fila.descripcionremitoestadotipo, far_remitoestadotipocc= fila.far_remitoestadotipocc, idremitoestadotipo= fila.idremitoestadotipo WHERE idremitoestadotipo= fila.idremitoestadotipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_remitoestadotipo(descripcionremitoestadotipo, far_remitoestadotipocc, idremitoestadotipo) VALUES (fila.descripcionremitoestadotipo, fila.far_remitoestadotipocc, fila.idremitoestadotipo);
    END IF;
    RETURN fila;
    END;
    $function$
