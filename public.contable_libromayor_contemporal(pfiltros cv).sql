CREATE OR REPLACE FUNCTION public.contable_libromayor_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 /*titulos.add("ASIENTO");
		titulos.add("COD CUENTA");
		titulos.add("CUENTA");
		titulos.add("FECHA");
		titulos.add("DESCRIPCION");
		titulos.add("DEBE");
		titulos.add("HABER");
		titulos.add("SALDO");
		titulos.add("OBSERVACIONES");*/

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_contable_libromayor_contemporal
AS (
	SELECT *
	  ,'1-ASIENTO#idasiento@2-COD CUENTA#codcuenta@3-FECHA#fechacontable@4-DESCRIPCION#concepto@5-DEBE#montoasientodebe@6-HABER#montoasientohaber@7-SALDO#dhsumatoria@8-OBSERVACIONES#obs'::text as mapeocampocolumna 
	     FROM (SELECT 
CAE.idAsiento, 
CAE.NroAsiento, 
CAE.FechaContable, 
--replace(replace(CAE.Concepto,'PAGO: ',''),'','',' ') AS Concepto, 
replace(CAE.Concepto,'PAGO: ','') AS Concepto,
CAE.Leyenda,
CAR.D_H, 
--CAR.Monto as MontoAsiento,
CASE WHEN CAR.D_H = 'D' THEN CAR.Monto ELSE 0 END as MontoAsientoDebe,
CASE WHEN CAR.D_H = 'H' THEN CAR.Monto ELSE 0 END as MontoAsientoHaber,
0 as MontoXCC,
0 as idCCosto,
''  as CentroDeCosto,
CC.CodCuenta,
CC.idCuenta, 
CC.Descripcion as Cuenta, 
CASE WHEN nullvalue(T.Sumatoria) THEN 0 ELSE T.Sumatoria END  as Sumatoria, CASE WHEN nullvalue(T.D_H) THEN 'S' ELSE T.D_H END as DHSumatoria,
CAE.idComprobante, 
CAE.idModulo,
'' as puntoDeVenta,
car.leyenda as obs
FROM multivac_CONT_Asientos_Encabezados cae 
 JOIN multivac_CONT_Asientos_Renglones car  ON cae.idasiento = car.idasiento
 JOIN multivac_CONT_Cuentas cc  ON cc.idcuenta = car.idcuenta
LEFT JOIN (SELECT sum(CA.Monto + CASE WHEN nullvalue(c.Monto) THEN 0 ELSE c.Monto END ) as Sumatoria, ca.idCuenta, ca.D_H
						FROM multivac_CONT_Asientos_Encabezados ce
						LEFT JOIN multivac_CONT_Asientos_Renglones ca  ON ce.idAsiento = ca.idAsiento
						LEFT JOIN multivac_CONT_Asientos_Renglones_CCosto c  ON c.idRenglon = ca.idRenglon
						WHERE CE.FechaContable <= rfiltros.FechaDesde AND extract('year' from FechaContable) = extract('year' from rfiltros.FechaDesde)
						
						GROUP BY CA.idCuenta, CA.D_H) T ON 
	(T.idCuenta = CC.idCuenta AND T.D_H = CAR.D_H)

WHERE 1 = 1
AND CAE.FechaContable >= rfiltros.FechaDesde
AND CAE.FechaContable <= rfiltros.FechaHasta
AND CC.CodCuenta >= rfiltros.CuentaDesde
AND CC.CodCuenta <= rfiltros.CuentaHasta

UNION ALL

SELECT 
0 as IdAsiento, 
0 as NroAsiento, 
rfiltros.FechaDesde::date - 1::integer FechaContable, 
'Acumulado' AS Concepto, 
'' Leyenda,
CAR.D_H, 
CASE WHEN CAR.D_H = 'D' THEN sum(CAR.Monto) ELSE 0 END as MontoAsientoDebe,
CASE WHEN CAR.D_H = 'H' THEN sum(CAR.Monto) ELSE 0 END as MontoAsientoHaber,
0 as MontoXCC,
0 as idCCosto, 
'' as CentroDeCosto,
max(CC.CodCuenta) as codCuenta, 
CC.idCuenta, 
max(CC.Descripcion) as Cuenta, 
0 as Sumatoria, 
'S' as DHSumatoria,
0 idComprobante, 
0 idModulo,
'' as puntoVenta,
'Acumulado anterior' as obs

FROM multivac_CONT_Asientos_Encabezados cae 
	INNER JOIN multivac_CONT_Asientos_Renglones car  ON cae.idAsiento = car.idAsiento
	INNER JOIN multivac_CONT_Cuentas cc ON cc.idCuenta = car.idCuenta
WHERE 1 = 1 AND CAE.Fechacontable < rfiltros.FechaDesde
AND CC.CodCuenta >= rfiltros.CuentaDesde
AND CC.CodCuenta <= rfiltros.CuentaHasta
GROUP BY car.d_h,cc.idcuenta
 order by fechaContable,nroasiento

) as t

order by fechaContable,nroasiento

	

);
  

return true;
END;
$function$
