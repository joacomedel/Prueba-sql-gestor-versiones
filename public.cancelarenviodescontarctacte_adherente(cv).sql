CREATE OR REPLACE FUNCTION public.cancelarenviodescontarctacte_adherente(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Funcion que asienta la cencelacion de los envios a descontar */
DECLARE
       rparam RECORD;
       cursormovimientos refcursor;
       unmovimiento RECORD;
       elnrodoc varchar;
       eltipodoc  integer;
BEGIN
     EXECUTE sys_dar_filtros($1) INTO rparam;
   --  elnrodoc = rparam.nrodoc;
   --  eltipodoc = rparam.tipodoc;

     OPEN cursormovimientos FOR SELECT *
                                FROM tmpctactedeudaenviar
                                JOIN ctactedeudacliente USING (iddeuda,idcentrodeuda);

    -- Actualizo fechaenvio en la deuda
    FETCH cursormovimientos into unmovimiento;
      WHILE  found LOOP
             UPDATE ctactedeudacliente SET ccdcfechaenvio = null
             WHERE iddeuda = unmovimiento.iddeuda AND idcentrodeuda = unmovimiento.idcentrodeuda;

             UPDATE enviodescontarctactev2 SET cancelado = true
             WHERE -- nrodoc =elnrodoc AND tipodoc = eltipodoc                     AND
                     idenviodescontarctacte = unmovimiento.idenviodescontarctacte
                     AND idcentromovimiento =unmovimiento.idcentrodeuda
                     AND idmovimiento = unmovimiento.iddeuda;
            FETCH cursormovimientos into unmovimiento;
      END LOOP;
      CLOSE cursormovimientos;



RETURN 'ok';
END;
$function$
