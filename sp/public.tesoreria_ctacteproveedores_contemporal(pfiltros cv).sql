CREATE OR REPLACE FUNCTION public.tesoreria_ctacteproveedores_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 
CREATE TEMP TABLE temp_tesoreria_ctacteproveedores_contemporal 
AS (
	select idcomp, fechamovimiento,fechavencimiento,movconcepto,debe,haber,saldo 
,'1-ID#idcomp@2-fecha movimiento#fechamovimiento@3-fecha vencimiento#fechavencimiento@4-Concepto#movconcepto@5-Debe#debe@6-Haber#haber@7-Saldo#saldo' as mapeocampocolumna

	from prestador as p
	natural join prestadorctacte as pc
	left join (
	select  debe.idcomp::varchar,  idctacte, to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento,to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechavencimiento,'Saldo inicio' as  movconcepto,case when nullvalue(debe.debe) then 0 else debe.debe end as debe,
	case when nullvalue(haber.haber) then 0 else haber.haber end as haber,
	(case when nullvalue(debe.debe) then 0 else debe.debe end)-(case when nullvalue(haber.haber) then 0 else haber.haber end) as saldo
	from
		(
		select  '0' as idcomp, idprestadorctacte as idctacte,to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento,'Saldo inicio' as  movconcepto, sum(importe) as debe
		from ctactedeudaprestador
		where fechamovimiento < to_date(rfiltros.fechadesde,'YYYY-MM-DD')
		      AND (rfiltros.textoConcepto='' OR ctactedeudaprestador.movconcepto ilike concat('%',rfiltros.textoConcepto,'%'))
		group by idctacte
		) as debe
	left join
		(
			select  '0' as idcomp, idprestadorctacte as idctacte,to_date(rfiltros.fechadesde,'YYYY-MM-DD') as fechamovimiento,'Saldo inicio' as  movconcepto, sum(importe*-1) as haber
			from ctactepagoprestador
			where fechamovimiento < to_date(rfiltros.fechadesde,'YYYY-MM-DD')
 			      AND (rfiltros.textoConcepto='' OR ctactedeudaprestador.movconcepto ilike concat('%',rfiltros.textoConcepto,'%'))
			group by idctacte
		) as haber using (idctacte)

	union

		select (iddeuda*100+idcentrodeuda)::varchar as idcomp, idprestadorctacte as idctacte,fechamovimiento,fechavencimiento,movconcepto, importe as debe,0 as haber,importe as saldo
		from ctactedeudaprestador
		where fechamovimiento between to_date(rfiltros.fechadesde,'YYYY-MM-DD') and to_date(rfiltros.fechahasta,'YYYY-MM-DD')
		      AND (rfiltros.textoConcepto='' OR ctactedeudaprestador.movconcepto ilike concat('%',rfiltros.textoConcepto,'%'))

	union

		
		select text_concatenar(concat((iddeuda*100+idcentrodeuda):: varchar,'|'))as idcomp,ctactepagoprestador.idprestadorctacte as idctacte,ctactepagoprestador.fechamovimiento,null as fechavencimiento,ctactepagoprestador.movconcepto, 0 as debe,ctactepagoprestador.importe*-1 as haber,ctactepagoprestador.importe as saldo
		from ctactepagoprestador
                LEFT JOIN ctactedeudapagoprestador USING(idpago,idcentropago)
                LEFT JOIN ctactedeudaprestador USING(iddeuda,idcentrodeuda)
		where ctactepagoprestador.fechamovimiento between to_date('2019-03-01','YYYY-MM-DD') and to_date('2019-05-30','YYYY-MM-DD')
		      AND (rfiltros.textoConcepto=''  OR ctactedeudaprestador.movconcepto ilike concat('%',rfiltros.textoConcepto,'%'))
                group by idpago,idcentropago
	) as cta on (pc.idprestadorctacte=cta.idctacte)
	where p.idprestador=rfiltros.idprestador
order by fechamovimiento
);
     

return true;
END;


$function$
