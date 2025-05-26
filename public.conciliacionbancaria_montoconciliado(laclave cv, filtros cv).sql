CREATE OR REPLACE FUNCTION public.conciliacionbancaria_montoconciliado(laclave character varying, filtros character varying)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$DECLARE

        rparam record;
            monto  double precision ;
            monto1  double precision ;
            resultado double precision ;
elidbancamovimiento bigint;

BEGIN

        EXECUTE sys_dar_filtros(filtros) INTO rparam;
        --RAISE NOTICE 'rparam(%)',rparam;
        monto = 0;
        monto1 = 0;
        resultado  = 0;
        IF(rparam.tipomov='banco') THEN
                  elidbancamovimiento = laclave::bigint;
                    SELECT INTO monto SUM(cbiimporte)
                    FROM conciliacionbancariaitem
                    WHERE cbiactivo 
                          and idbancamovimiento = elidbancamovimiento 
                          -- se reemplazazo   por...
                          --- vuelvo a reemplazar VAS 280122 y deje solo la busqueda por idbancamovieminteo  and (idbancamovimiento = laclave  or  cbiclavecompsiges =laclave   )
              
                    GROUP BY idbancamovimiento;
                    if not found then monto  = 0;
                        end if;

---------------------------------------------------------------------------------------------------------------------
-- VyD 28102020
              
--Dani lo comento el 24-03-2021 porq quedaban mov del banco  pendientes de conciliar cuando ya habian sido conciliados
--Dani lo descomento el 29-03-2021 porq quedaban no se volvian a aver los movimientos liberados
--Dani lo comento el 03-05-2021 porq quedaban mov del banco  pendientes de conciliar cuando ya habian sido conciliados
/*
    SELECT INTO monto1 SUM(cbiimporte) 
                    FROM conciliacionbancariaitem
                    WHERE cbiactivo 
                          and (cbiclavecompsiges like laclave AND  cbitablacomp like 'bancamovimiento') 
                    GROUP BY idbancamovimiento;
                    if not found then monto1 = 0;
                    end if;
 */
                   resultado  = abs( monto - monto1) ;
                         --RAISE NOTICE '>>>>>>>>>>>>>>>>>>>>>>< conciliacionbancaria_montoconciliado resultado  (%)',resultado  ;

-- VyD 28102020
---------------------------------------------------------------------------------------------------------------------

        END IF;
        IF(rparam.tipomov='siges') THEN
           -- RAISE NOTICE '>>>>>>>>>>>>>>>>>>>>>>< conciliacionbancaria_montoconciliado  laclave(%)',laclave;
           -- RAISE NOTICE '>>>>>>>>>>>>>>>>>>>>>>< conciliacionbancaria_montoconciliado  rparam.tabla(%)',rparam.tabla;
            SELECT  INTO resultado   SUM(cbiimporte)
            FROM conciliacionbancariaitem as cbi
            JOIN conciliacionbancaria USING (idconciliacionbancaria,idcentroconciliacionbancaria) 
            JOIN cuentabancariasosunc using(idcuentabancaria)
            WHERE nrocuentac  = rparam.nrocuentac
               AND cbiactivo and cbiclavecompsiges like laclave
               AND  cbitablacomp like rparam.tabla;
            

    ELSE
        -- RAISE NOTICE '>>>>>>>>>>>>>>>>>>>>>>< conciliacionbancaria_montoconciliado  este es el else';

     END IF;

     IF nullvalue( resultado  ) THEN resultado  =0; END IF;

RETURN resultado  ;
END;
$function$
