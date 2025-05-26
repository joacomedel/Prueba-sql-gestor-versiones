CREATE OR REPLACE FUNCTION public.insertarccfar_obrasocialmutual(fila far_obrasocialmutual)
 RETURNS far_obrasocialmutual
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_obrasocialmutualcc:= current_timestamp;
    UPDATE sincro.far_obrasocialmutual SET far_obrasocialmutualcc= fila.far_obrasocialmutualcc, idmutual= fila.idmutual, idobrasocial= fila.idobrasocial, osmmultiplicador= fila.osmmultiplicador WHERE idmutual= fila.idmutual AND idobrasocial= fila.idobrasocial AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_obrasocialmutual(far_obrasocialmutualcc, idmutual, idobrasocial, osmmultiplicador) VALUES (fila.far_obrasocialmutualcc, fila.idmutual, fila.idobrasocial, fila.osmmultiplicador);
    END IF;
    RETURN fila;
    END;
    $function$
