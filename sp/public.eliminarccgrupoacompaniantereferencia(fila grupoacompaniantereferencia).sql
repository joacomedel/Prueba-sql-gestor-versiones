CREATE OR REPLACE FUNCTION public.eliminarccgrupoacompaniantereferencia(fila grupoacompaniantereferencia)
 RETURNS grupoacompaniantereferencia
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.grupoacompaniantereferenciacc:= current_timestamp;
    delete from sincro.grupoacompaniantereferencia WHERE nrodoctitular= fila.nrodoctitular AND tipodoctitular= fila.tipodoctitular AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
