CREATE OR REPLACE FUNCTION public.insertarccfar_obrasocialvalorescaja(fila far_obrasocialvalorescaja)
 RETURNS far_obrasocialvalorescaja
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_obrasocialvalorescajacc:= current_timestamp;
    UPDATE sincro.far_obrasocialvalorescaja SET far_obrasocialvalorescajacc= fila.far_obrasocialvalorescajacc, idobrasocial= fila.idobrasocial, idvalorescaja= fila.idvalorescaja WHERE idobrasocial= fila.idobrasocial AND idvalorescaja= fila.idvalorescaja AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_obrasocialvalorescaja(far_obrasocialvalorescajacc, idobrasocial, idvalorescaja) VALUES (fila.far_obrasocialvalorescajacc, fila.idobrasocial, fila.idvalorescaja);
    END IF;
    RETURN fila;
    END;
    $function$
