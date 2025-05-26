CREATE OR REPLACE FUNCTION public.eliminarccmanextra(fila manextra)
 RETURNS manextra
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.manextracc:= current_timestamp;
    delete from sincro.manextra WHERE mnroregistro= fila.mnroregistro AND nomenclado= fila.nomenclado AND TRUE;
    RETURN fila;
    END;
    $function$
