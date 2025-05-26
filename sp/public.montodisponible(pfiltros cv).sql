CREATE OR REPLACE FUNCTION public.montodisponible(pfiltros character varying)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD                  
rfiltros RECORD; 

--VARIABLES 
vmontodisponible DOUBLE PRECISION;
                          
BEGIN
 
      vmontodisponible = 0;
      EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


    -- DS 09/04/25 cambio la consulta, le saco nullvalue() y uso el is null porque tarda menos la consulta
    --   SELECT INTO vmontodisponible case when nullvalue((ccmdimporte-ccmdmontoconsumido)) then 0 else (ccmdimporte-ccmdmontoconsumido) END
    --   FROM persona 
    --   NATURAL JOIN  afilsosunc afs 
    --   LEFT JOIN benefsosunc bs ON (afs.nrodoc= bs.nrodoctitu AND afs.tipodoc= bs.tipodoctitu)
    --   LEFT JOIN ctasctesmontosdescuento ccmd ON (afs.nrodoc= ccmd.nrodoc AND afs.tipodoc= ccmd.tipodoc)  
    --   WHERE(afs.nrodoc=rfiltros.nrodoc 
    --               OR (bs.nrodoc = rfiltros.nrodoc AND estaactivo)) 
    --         AND nullvalue(ccmdfechafin) 
    --         AND (barra <>35 and barra <>36); 

    SELECT INTO vmontodisponible case when nullvalue((ccmdimporte-ccmdmontoconsumido)) then 0 else (ccmdimporte-ccmdmontoconsumido) END
        FROM persona NATURAL JOIN  afilsosunc afs 
        LEFT JOIN benefsosunc bs ON (afs.nrodoc= bs.nrodoctitu AND afs.tipodoc= bs.tipodoctitu)
        LEFT JOIN ctasctesmontosdescuento ccmd ON (afs.nrodoc= ccmd.nrodoc AND afs.tipodoc= ccmd.tipodoc)  
        WHERE(afs.nrodoc=rfiltros.nrodoc 
            OR (bs.nrodoc = rfiltros.nrodoc AND estaactivo)) 
                AND ccmdfechafin IS NULL
                AND (barra <>35 and barra <>36); 

      IF NOT FOUND THEN 
        vmontodisponible = 0;
      END IF;
 

      return vmontodisponible;

END;$function$
