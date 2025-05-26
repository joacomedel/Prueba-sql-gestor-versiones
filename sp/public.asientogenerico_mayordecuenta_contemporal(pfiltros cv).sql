CREATE OR REPLACE FUNCTION public.asientogenerico_mayordecuenta_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
       cmayor refcursor;
       cconfig  refcursor;
       rmayor RECORD;
BEGIN

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

   -- DROP TABLE temp_asientogenerico_mayordecuenta_contemporal;
/*
IF (rfiltros.nrocuentac = 10321 AND rfiltros.fechaDesde='2021-01-01' and rfiltros.fechaHasta='2021-12-31') THEN 

        CREATE TEMP TABLE temp_asientogenerico_mayordecuenta_contemporal   AS (
        select *
        from (
             SELECT *
             FROM asientogenerico_mayordecuenta_10321_2021 )as a
       );
	 
 
ELSE 
 
*/

    CREATE TEMP TABLE temp_asientogenerico_mayordecuenta_contemporal
    -- CREATE TABLE temp_asientogenerico_mayordecuenta_contemporal
     AS (
        select *
        ,'1-ASIENTO#idasiento@2-COD CUENTA#codcuenta@3-CUENTA#cuenta@4-FECHA#fechacontable@5-DESCRIPCION#concepto@6-DEBE#debe@7-HABER#haber@8-SALDO#saldo<+>@9-IDComprobante#elidsiges@10-OBSERVACION#leyenda@11-Diferencia#diferencia'::text as mapeocampocolumna
        from (
             SELECT 
                    rfiltros.fechaDesde,
                    rfiltros.fechaHasta,
                    (CAE.idasientogenerico*100) + CAE.idcentroasientogenerico as idAsiento,
                    CAE.idcentroasientogenerico,
                    CAE.idasientogenerico as NroAsiento,
                    (to_char(CAE.agfechacontable, 'DD-MM-YYYY'))::date as fechacontable,
                    CAE.agdescripcion AS Concepto,
                    '' as Leyenda,
                    CAR.acid_h as D_H,
                    case when CAR.acid_h='D' then CAR.acimonto else 0 end as debe,
                    case when CAR.acid_h='H' then CAR.acimonto else 0 end as haber,
                    (case when CAR.acid_h='D' then CAR.acimonto else 0 end)-(case when CAR.acid_h='H' then CAR.acimonto else 0 end) as saldo,
                    CAR.acimonto as MontoAsiento,
                    0 as MontoXCC,
                    0 as idCCosto,
                    '' as CentroDeCosto,
                    CC.nrocuentac as CodCuenta,
                    CC.nrocuentac as idCuenta,
                    CC.desccuenta as Cuenta,
                    0 as Sumatoria,
                    '' as DHSumatoria,
    /*  CAE.idcomprobantesiges as elidsiges,*/
                     CAE.idcomprobantesiges as elidsiges,
                    CAE.idasientogenericocomprobtipo as idModulo,
                    '' as puntoDeVenta,
                    car.acidescripcion as obs,
                    idasientogenericocomprobtipo,
                    concat(idasientogenericoitem,'|',idcentroasientogenericoitem) as itemasiento   -- esta info se utiliza para hacer referencia al item de la conc.
                    ,idasientogenericoitem
                    ,idcentroasientogenericoitem
                    ,0.0 as diferencia
                    FROM asientogenerico CAE
                    natural join asientogenericoitem CAR
                    natural join cuentascontables CC
                  NATURAL JOIN asientogenericoestado
                    --MaLaPi 09-01-2018 La contabilidad existe en Siges a partir del 01-01-2019, lo anterior no debe figurar en el reporte mayor. Pidio Victor Novoa

                    where CAE.agfechacontable >= '2019-01-01' AND  agfechacontable between rfiltros.fechaDesde and rfiltros.fechaHasta
                          and (nrocuentac='' or nrocuentac=rfiltros.nrocuentac)
                       and (agefechafin) IS NULL  -- BelenA 07-05-25 cambio nullvalue por is null
             and tipoestadofactura <> 5
                  
                    
         UNION

         SELECT
               rfiltros.fechaDesde,
               rfiltros.fechaHasta,
               0 as IdAsiento,
               0 as idcentroasientogenerico,
               0 as NroAsiento,
               (to_char((rfiltros.fechaDesde::date + INTERVAL'-1 day'), 'DD-MM-YYYY'))::date as fechacontable,
               'Acumulado' as Concepto,
               '' as Leyenda,
               CAR.acid_h as D_H,
               case when CAR.acid_h='D' then round(sum(CAR.acimonto) ::numeric,2) else 0 end as debe,
               case when CAR.acid_h='H' then round(sum(CAR.acimonto) ::numeric,2) else 0 end as haber,
               (case when CAR.acid_h='D' then sum(CAR.acimonto) else 0 end)-(case when CAR.acid_h='H' then sum(CAR.acimonto) else 0 end) as saldo,
               sum(CAR.acimonto) as MontoAsiento,
               0 as MontoXCC,
               0 as idCCosto,
               '' as CentroDeCosto,
               max(CC.nrocuentac) as codCuenta,
               CC.nrocuentac idCuenta,
               max(CC.desccuenta) as Cuenta,
               0 as Sumatoria,
               'S' as DHSumatoria,
               '' as elidsiges,
               0 as idModulo,
               '' as puntoVenta,
               'Acumulado anterior' as obs
               ,0 as idasientogenericocomprobtipo
               ,'0|0'
               ,0 as idasientogenericoitem
               ,0 as idcentroasientogenericoitem
              ,0.0 as diferencia
               FROM asientogenerico CAE
               NATURAL JOIN asientogenericoitem CAR
               NATURAL JOIN cuentascontables CC
          NATURAL JOIN asientogenericoestado
               --MaLaPi 09-01-2018 La contabilidad existe en Siges a partir del 01-01-2019, lo anterior no debe figurar en el reporte mayor. Pidio Victor Novoa
               WHERE CAE.agfechacontable >= '2019-01-01' AND CAE.agfechacontable < rfiltros.fechaDesde
                     and (nrocuentac='' or nrocuentac=rfiltros.nrocuentac)
                 and (agefechafin) IS NULL  -- BelenA 07-05-25 cambio nullvalue por is null
            and tipoestadofactura <> 5
               GROUP BY car.acid_h,cc.nrocuentac

               order by fechacontable
--,nroasiento,leyenda
       ) as x
--CS 2019-05-27 El orden en las filas viene dado por la fecha. Pidió Liliana Freeman
--  order by idcentroasientogenerico,FechaContable::date,Leyenda,NroAsiento
  order by fechacontable
--::date,nroasiento,leyenda
-- -- -- - -- -- -- -- 
--LIMIT 100
    );

  OPEN  cmayor FOR
          SELECT * FROM temp_asientogenerico_mayordecuenta_contemporal order by fechacontable;
    FETCH cmayor INTO rmayor;
    WHILE FOUND LOOP
          UPDATE temp_asientogenerico_mayordecuenta_contemporal as t
          SET Leyenda = contabilidad_info(concat('{idasientogenericoitem=',rmayor.idasientogenericoitem,',idcentroasientogenericoitem=',rmayor.idcentroasientogenericoitem,',nrocuentac=',rmayor.idCuenta,',acid_h=',rmayor.D_H,'}'))
          WHERE t.idasientogenericoitem = rmayor.idasientogenericoitem
                and t.idcentroasientogenericoitem = rmayor.idcentroasientogenericoitem
                AND idasientogenericoitem <>0;
          FETCH cmayor INTO rmayor;
    END LOOP;

  -- corroboro si se calcula diferencia d/h de los paquetitos
  SELECT INTO cconfig * FROM  contabilidad_mayorinfo WHERE cmcalcular_dif_d_h = true and nrocuentac=rfiltros.nrocuentac;
  IF FOUND THEN
         UPDATE temp_asientogenerico_mayordecuenta_contemporal 
--X MAIL DE ANDREA (ASUNTO DEUDORES POR ADHERENTES) SE MODIFICA
		 SET  leyenda = t.leyenda
                      ,diferencia = t.diferencia
		 FROM (
                SELECT count(*) as cant , leyenda,round(SUM(debe) ::numeric,2), round(SUM(haber) ::numeric,2)  haber,
                       abs(round(SUM(debe) ::numeric,2)- round(SUM(haber) ::numeric,2)) as diferencia
                FROM temp_asientogenerico_mayordecuenta_contemporal
                group by  leyenda
        )as t
        WHERE  t.leyenda = temp_asientogenerico_mayordecuenta_contemporal.leyenda;  
  END IF;
---END IF;
RETURN true;
END;
$function$
