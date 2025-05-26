CREATE OR REPLACE FUNCTION ca.as_diferenciaredondeo(integer, integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$
/* PARAMETROS : $1 mes
              $2 anio
              $3 idcentrocosto
              $4 nroctacble
              $5 idasientosueldotipo
*/
DECLARE

       elmes integer;
       elanio integer;
       elidasiento integer;
       elidtipoliquidacion integer;
       elidasientosueldoctactble integer;
       elidcentrocosto integer;
       elnroctacble varchar;
       laformula varchar;
       elmonto double precision;
       impdebe double precision;
       imphaber double precision;
       impdiferencia double precision;
       elredondeo record;
BEGIN
     SET search_path = ca, pg_catalog;
     elmes = $1;
     elanio = $2;
     elidcentrocosto =  $3;
     elnroctacble = $4;
     elidasientosueldoctactble=$5;

      SELECT INTO elredondeo *
      FROM ca.asientosueldo
      NATURAL JOIN  ca.asientosueldotipoctactble
      NATURAL JOIN  ca.asientosueldoctactble
      WHERE idasientosueldoctactble = elidasientosueldoctactble and lianio = elanio and limes =elmes;
      
      SELECT  INTO impdebe 	sum(ascimporte) as debe,idasientosueldo	
      FROM   ca.asientosueldo
      NATURAL JOIN   ca.asientosueldotipoctactble
      NATURAL JOIN  ca.asientosueldoctactble
      WHERE nrocuentac <> 50876 and  limes=elmes and lianio=elanio and idasientosueldotipo=elredondeo.idasientosueldotipo
            and nullvalue(asfecha) and  not ascactivo and asvigente
     GROUP BY idasientosueldo , idasientosueldotipo, ascactivo;

     SELECT	INTO imphaber	sum(ascimporte) as haber,idasientosueldo
     FROM  ca.asientosueldo
     NATURAL JOIN ca.asientosueldotipoctactble
     NATURAL JOIN  ca.asientosueldoctactble
     WHERE nrocuentac <> 50876 and limes=elmes and lianio=elanio and idasientosueldotipo=elredondeo.idasientosueldotipo
            and nullvalue(asfecha)  and  ascactivo	 and asvigente
     GROUP BY  idasientosueldo ,idasientosueldotipo, ascactivo;

     
    
     impdiferencia = 0;
     -- corroboro si es un redondeo que debe afectar al debe o al haber
     if (elredondeo.ascactivo ) THEN -- debe afectar al haber
              -- debo ajustar si el haber es < debe
              if (imphaber< impdebe) THEN
                 impdiferencia = impdebe - imphaber;
              END IF;
               
     ELSE -- debe afectar al debe
             if (impdebe < imphaber) THEN
                 impdiferencia = imphaber - impdebe  ;
              END IF;

     END IF;
     /*if (impdiferencia <= 0 ) THEN
        impdiferencia = 0;
     END IF;

     UPDATE ca.asientosueldoctactble  SET ascimporte = impdiferencia
     WHERE idasientosueldo = elredondeo.idasientosueldo and idasientosueldoctactble = elidasientosueldoctactble;
     */
return 	impdiferencia;
END;
$function$
