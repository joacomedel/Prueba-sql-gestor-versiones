CREATE OR REPLACE FUNCTION public.tesoreria_ctacteproveedores_contemporal(pfechadesde date, pfechahasta date, pidprestador character varying, ptiporeporte character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
BEGIN
 
CREATE TEMP TABLE temp_tesoreria_ctacteproveedores_contemporal 
AS (
	select  idcomp, fechacomprobante::date,fechavencimiento,movconcepto,impago,debe,haber,saldo--sum(saldo) as saldo
,'1-ID#idcomp@2-Fecha Comprobante#fechacomprobante@3-fecha vencimiento#fechavencimiento@4-Concepto#movconcepto@5-Imp.Pagado#impago@6-Debe#debe@7-Haber#haber@8-Saldo#saldo' as mapeocampocolumna
	from prestador as p
	natural join prestadorctacte as pc
	left join (
	select debe.idcomp::varchar,idctacte, to_date(pfechadesde,'YYYY-MM-DD') as fechacomprobante,to_date(pfechadesde,'YYYY-MM-DD') as fechavencimiento,'Saldo inicio' as  movconcepto,case when nullvalue(debe.debe) then 0 else debe.debe end as debe,
	case when nullvalue(haber.haber) then 0 else haber.haber end as haber,
	 (case when nullvalue(debe.debe) then 0 else debe.debe end) - (case when nullvalue(haber.haber) then 0 else haber.haber end)  as saldo,debe.impago-haber.impago as impago
	from
		(
		select  '0' as idcomp,idprestadorctacte as idctacte,to_date(pfechadesde,'YYYY-MM-DD') as fechacomprobante,'Saldo inicio' as  movconcepto, sum(importe) as debe,sum(saldo) as impago
		from ctactedeudaprestador
		where fechamovimiento < to_date(pfechadesde,'YYYY-MM-DD')
		group by idctacte
		) as debe
	left join
		(
			select '0' as idcomp,idprestadorctacte as idctacte,to_date(pfechadesde,'YYYY-MM-DD') as fechacomprobante,'Saldo inicio' as  movconcepto, sum(importe*-1) as haber,sum(saldo) as impago
			from ctactepagoprestador
			where fechacomprobante < to_date(pfechadesde,'YYYY-MM-DD')
			group by idctacte
		) as haber using (idctacte)

	union

		select (iddeuda*100+idcentrodeuda)::varchar as idcomp, idprestadorctacte as idctacte,fechamovimiento as fechacomprobante,fechavencimiento,movconcepto, importe as debe,0 as haber,importe as saldo,saldo as impago
		from ctactedeudaprestador
		where fechamovimiento between to_date(pfechadesde,'YYYY-MM-DD') and to_date(pfechahasta,'YYYY-MM-DD')

	union

		
                select text_concatenar(concat((iddeuda*100+idcentrodeuda):: varchar,'|'))as idcomp,ctactepagoprestador.idprestadorctacte as idctacte,ctactepagoprestador.fechamovimiento,null as fechavencimiento,ctactepagoprestador.movconcepto, 0 as debe,ctactepagoprestador.importe*-1 as haber,ctactepagoprestador.importe as saldo,ctactepagoprestador.saldo as impago
		from ctactepagoprestador
                LEFT JOIN ctactedeudapagoprestador USING(idpago,idcentropago)
                LEFT JOIN ctactedeudaprestador USING(iddeuda,idcentrodeuda)
		where fechacomprobante between to_date(pfechadesde,'YYYY-MM-DD') and to_date(pfechahasta,'YYYY-MM-DD')
                group by idpago,idcentropago




	) as cta on (pc.idprestadorctacte=cta.idctacte)
	where p.idprestador=pidprestador
     --   GROUP BY fechacomprobante,fechavencimiento,movconcepto,debe,haber,impago
order by fechacomprobante,fechavencimiento
 
);
     

return true;
END;
$function$
