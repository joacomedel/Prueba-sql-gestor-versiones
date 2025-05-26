CREATE OR REPLACE FUNCTION public.libroiva_ventas_contabilidad_balancecontable(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
	   rperiodo RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

SELECT INTO rperiodo * FROM contabilidad_periodofiscal  
WHERE pftipoiva = 'V' AND pffechadesde >= rfiltros.fechaDesde AND pffechahasta <= rfiltros.fechaHasta
ORDER BY  	idperiodofiscal DESC;
IF FOUND THEN 
	perform libroiva_ventas_contemporal(concat('{idperiodofiscal=',rperiodo.idperiodofiscal,' ,fechaHasta=',rperiodo.pffechadesde,', fechaDesde=',rperiodo.pffechahasta,'}'));
	--SELECT * FROM temp_libroiva_ventas_contemporal;

END IF;

CREATE TEMP TABLE temp_contabilidad_balancecontable_contemporal
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
idasientogenerico,idcentroasientogenerico,agfechacontable,agfechacreacion,
round(CAST (A.debe AS numeric),2)::float debe,
round(CAST (A.haber AS numeric),2)::float haber 
,round(CAST ( (A.debe-A.haber) AS numeric),2)::float as saldo
from cuentascontables c
natural join multivac.mapeocuentascontables m
join 
(
	select  idasientogenerico,idcentroasientogenerico,agfechacontable,agfechacreacion,nrocuentac,debe,haber
	from
	(
	SELECT idasientogenerico,idcentroasientogenerico,agfechacontable,agfechacreacion,nrocuentac, 	
		acimonto as debe,
		0 as Haber
		FROM asientogenericoitem AF
		natural join asientogenerico AG
        natural join 
                (select * from asientogenericoestado where nullvalue(agefechafin) and tipoestadofactura<>5) estado
		WHERE acid_h='D' and AG.agfechacontable between to_date(rfiltros.fechaDesde,'YYYY-MM-DD') and to_date(rfiltros.fechaHasta,'YYYY-MM-DD')
	union
	SELECT 
		idasientogenerico,idcentroasientogenerico,agfechacontable,agfechacreacion,nrocuentac, 	
		0 as debe,
		acimonto as haber
		FROM  asientogenericoitem AF
		natural join asientogenerico AG
        natural join 
                (select * from asientogenericoestado where nullvalue(agefechafin) and tipoestadofactura<>5) estado
		WHERE acid_h='H' and AG.agfechacontable between to_date(rfiltros.fechaDesde,'YYYY-MM-DD') and to_date(rfiltros.fechaHasta,'YYYY-MM-DD')
	) as x
) A on (c.nrocuentac=A.nrocuentac)
	WHERE substring(m.Jerarquia,1,1) = '5'
ORDER BY m.Jerarquia
);     

--UPDATE  temp_libroiva_ventas_contemporal SET losasientos = replace(replace(replace(losasientos,' ',''),'(',''),')','-');
--UPDATE  temp_libroiva_ventas_contemporal SET losasientos = left(losasientos,length(losasientos)-1);

DROP TABLE losasientostodos;
CREATE TABLE losasientostodos AS (
SELECT idasientogenerico,idcentroasientogenerico,'balance' as origen,'No esta en IVA' as diferencia
FROM temp_contabilidad_balancecontable_contemporal
LEFT JOIN 
	(SELECT idcomprobantesiges,idasientogenerico,idcentroasientogenerico
   		FROM asientogenerico
   		JOIN temp_libroiva_ventas_contemporal USING(idcomprobantesiges)
   	WHERE asientogenerico.agfechacontable >= '2019-01-01'::date
 	) as iva USING(idasientogenerico,idcentroasientogenerico)
WHERE nullvalue(iva.idasientogenerico)
UNION 
SELECT idasientogenerico,idcentroasientogenerico,'balance-iva' as origen,'esta en los dos' as diferencia
FROM temp_contabilidad_balancecontable_contemporal
JOIN 
	(SELECT idcomprobantesiges,idasientogenerico,idcentroasientogenerico
   		FROM asientogenerico
   		JOIN temp_libroiva_ventas_contemporal USING(idcomprobantesiges)
   	WHERE asientogenerico.agfechacontable >= '2019-01-01'::date
) as iva USING(idasientogenerico,idcentroasientogenerico)
UNION 
SELECT idasientogenerico,idcentroasientogenerico,'iva' as origen,'no esta en balance' as diferencia
FROM 
	(SELECT idcomprobantesiges,idasientogenerico,idcentroasientogenerico
   		FROM asientogenerico
   		JOIN temp_libroiva_ventas_contemporal USING(idcomprobantesiges)
   	WHERE asientogenerico.agfechacontable >= '2019-01-01'::date
) as iva
LEFT JOIN temp_contabilidad_balancecontable_contemporal 
	 USING(idasientogenerico,idcentroasientogenerico)
WHERE nullvalue(temp_contabilidad_balancecontable_contemporal.idasientogenerico)
);									
								
	
return true;
END;
$function$
