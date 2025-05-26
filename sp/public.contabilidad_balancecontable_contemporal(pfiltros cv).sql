CREATE OR REPLACE FUNCTION public.contabilidad_balancecontable_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

perform contabilidad_calcularsaldoscontables(to_date(rfiltros.fechaDesde,'YYYY-MM-DD'));

CREATE TEMP TABLE temp_contabilidad_balancecontable_contemporal 
-- CREATE  TABLE temp_contabilidad_balancecontable_contemporal_ixi 
--DROP TABLE balance_sumasysaldos2022;
--CREATE TABLE balance_sumasysaldos2022  
AS (
SELECT c.nrocuentac as idCuenta,c.nrocuentac CodCuenta,c.desccuenta as Descripcion,m.Jerarquia,m.saldohabitual D_H,
case substring(m.Jerarquia,1,1)
	when '1' then  'ACTIVO'
	when '2' then 'PASIVO'
	when '3' then 'PATRIMONIO NETO'
	when '4' then 'INGRESOS'
	when '5' then 'EGRESOS'
	else 'MOVIMIENTO'
end as  grupo,

--case when to_date(rfiltros.fechaDesde,'YYYY-MM-DD')<='2019-01-01' then 0 else s.ccssaldodebe end SaldoAnteriorDebe,  --VAS 23-03-2022
 s.ccssaldodebe SaldoAnteriorDebe,  --VAS 23-03-2022 descomento

-- case when to_date(rfiltros.fechaDesde,'YYYY-MM-DD')<='2019-01-01' then 0 else s.ccssaldohaber end SaldoAnteriorHaber,        --VAS 23-03-2022

s.ccssaldohaber SaldoAnteriorHaber, --VAS 23-03-2022 descomento
round(CAST (A.debe AS numeric),2)::float debe ,
round(CAST (A.haber AS numeric),2)::float haber 

--VAS 23-03-2022 modifique el sp contabilidad_saldocontable para que tenga en cuenta los movimientos a partir del 2019
--,case when to_date(rfiltros.fechaDesde,'YYYY-MM-DD')<='2019-01-01' then 0 else s.ccssaldodebe-s.ccssaldohaber end saldoanterior --VAS 23-03-2022

, (s.ccssaldodebe-s.ccssaldohaber ) as saldoanterior --VAS 23-03-2022 descomento

-- VAS 29-03-2022
-- ,round(CAST ( (A.debe-A.haber) AS numeric),2)::float as saldo  no esta teniendo en cuenta el saldo inicial de la cuenta
,round(CAST ( (( s.ccssaldodebe-s.ccssaldohaber )+ (A.debe-A.haber)) AS numeric),2)::float as saldo

,'1-Grupo#grupo@2-Cuenta#codcuenta@3-Descripcion#descripcion@4-Saldo Anterior#saldoanterior@5-Debe#debe@6-Haber#haber@7-Saldo#saldo'::text as mapeocampocolumna

	
FROM cuentascontables c
NATURAL JOIN multivac.mapeocuentascontables m
LEFT JOIN (
	SELECT  nrocuentac,sum(debe) debe,sum(haber) haber
	FROM(
	     -- ACUMULADO de cada cuenta contable en el Haber
	     SELECT AF.nrocuentac, sum(acimonto) as Debe, 0 as Haber
  	     FROM asientogenericoitem AF
	     NATURAL JOIN  asientogenerico AG
         NATURAL JOIN (SELECT * FROM asientogenericoestado WHERE nullvalue(agefechafin) AND tipoestadofactura<>5) estado
         WHERE acid_h='D' 
			   and AG.agfechacontable between to_date(rfiltros.fechaDesde,'YYYY-MM-DD') and to_date(rfiltros.fechaHasta,'YYYY-MM-DD')
	     GROUP BY nrocuentac
	
         UNION
	     -- ACUMULADO de cada cuenta contable en el Haber
         SELECT AF.nrocuentac, 0 as Debe, sum(acimonto) as Haber
	     FROM asientogenericoitem AF
	     NATURAL JOIN asientogenerico AG
         NATURAL JOIN (select * from asientogenericoestado where nullvalue(agefechafin) and tipoestadofactura<>5) estado
    	 WHERE acid_h='H' 
		       and AG.agfechacontable between to_date(rfiltros.fechaDesde,'YYYY-MM-DD') and to_date(rfiltros.fechaHasta,'YYYY-MM-DD')
	     GROUP BY nrocuentac
	) as x
	GROUP BY nrocuentac 
) A on (c.nrocuentac=A.nrocuentac)
LEFT JOIN  contabilidad_cuentasconsaldo as s on (c.nrocuentac=s.nrocuentac)
--where m.imputable
where s.nrocuentac <> '99999' --- VAS 250425 es una cuenta compensadora de saldo  migracion siges-multivac 
ORDER BY m.Jerarquia
);     

return true;
END;

$function$
