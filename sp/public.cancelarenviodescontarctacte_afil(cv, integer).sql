CREATE OR REPLACE FUNCTION public.cancelarenviodescontarctacte_afil(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Funcion que asienta la cencelacion de los envios a descontar */
DECLARE
       cursormovimientos refcursor;
       unmovimiento RECORD;
       elnrodoc varchar;
       eltipodoc  integer;
BEGIN
     elnrodoc = $1;
     eltipodoc = $2;
--( idenviodescontarctacte  BIGINT, iddeuda BIGINT , idcentrodeuda INTEGER NOT NULL, tipodoc  INTEGER , nrodoc VARCHAR);
     OPEN cursormovimientos FOR SELECT *
                                FROM tmpctactedeudaenviar
                                JOIN cuentacorrientedeuda USING (iddeuda,idcentrodeuda);

    -- Actualizo fechaenvio en la deuda
    FETCH cursormovimientos into unmovimiento;
      WHILE  found LOOP
             UPDATE cuentacorrientedeuda SET fechaenvio = null
             WHERE iddeuda = unmovimiento.iddeuda AND idcentrodeuda = unmovimiento.idcentrodeuda;

             UPDATE enviodescontarctactev2 SET cancelado = true
             WHERE  nrodoc =elnrodoc AND tipodoc = eltipodoc
                     AND idenviodescontarctacte = unmovimiento.idenviodescontarctacte
                     AND idcentromovimiento =unmovimiento.idcentrodeuda
                     AND idmovimiento = unmovimiento.iddeuda;
            FETCH cursormovimientos into unmovimiento;
      END LOOP;
      CLOSE cursormovimientos;



RETURN TRUE;
END;
$function$
