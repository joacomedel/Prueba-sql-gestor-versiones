CREATE OR REPLACE FUNCTION ca.antiguedadlao(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


lapersona bigint;


BEGIN
SET search_path = ca, pg_catalog;

lapersona = $1;


--obtengo la cantidad en dias para lao y la antiguedad en anios, meses y dias
insert into tempantiguedad(idpersona,emfechadesde,diaslao,diassosunc,mesessosunc,
aniossosunc,aniosotros,mesesotros,diasotros,totaldiassosunc,
totaldiasotros,totalanios,totalmeses,totaldias)
(select *,
(totaldiassosunc+totaldiasotros)/365 as totalanios,
((totaldiassosunc+totaldiasotros)%365)/30 as totalmeses,
((totaldiassosunc+totaldiasotros)%365)%30 as totaldias
 from 
(select
idpersona,
emfechadesde,
case when t.anios>20 then 40 
else
case when t.anios<=20 and t.anios>=16  then 35 
 else
case when t.anios>=11 and t.anios<=15 then 30 
 else
case when t.anios>=6 and t.anios<=10 then 25
 else
case when t.anios<=5 then 20
end 
end
end
end
end as diaslao,t.dias,t.meses,t.anios,
(sum(alfechafin-alfechainicio))/365 as aniosotros,
((sum(alfechafin-alfechainicio))%365)/30 as mesesotros,
((sum(alfechafin-alfechainicio))%365)%30 as diasotros,
 
case when (to_date( concat(EXTRACT(YEAR FROM CURRENT_date)-1  ,'-12','-31'),'YYYY-MM-DD') -
emfechadesde >0) then 
to_date(concat(EXTRACT(YEAR FROM CURRENT_date)-1  ,'-12','-31'),'YYYY-MM-DD') -
emfechadesde else 0 end as totaldiassosunc,

case when ((sum(alfechafin-alfechainicio))>0) then sum(alfechafin-alfechainicio)
else 0 end as totaldiasotros

from 
(
select 
extract(day from age(to_date(concat(EXTRACT(YEAR FROM CURRENT_date)-1  ,'-12','-31'),'YYYY-MM-DD') ::TIMESTAMP,
                       emfechadesde::TIMESTAMP)
) as dias,
extract(month from age(to_date(concat(EXTRACT(YEAR FROM CURRENT_date)-1  ,'-12','-31'),'YYYY-MM-DD') ::TIMESTAMP,emfechadesde::TIMESTAMP)) as meses,
extract(year from age(to_date(concat(EXTRACT(YEAR FROM CURRENT_date)-1  ,'-12','-31'),'YYYY-MM-DD') ::TIMESTAMP,emfechadesde::TIMESTAMP)) as anios
,alfechafin,alfechainicio,
idpersona,emfechadesde

from ca.empleado natural join ca.persona left join  ca.actividadlaboral
using(idpersona)  where (idpersona=lapersona or lapersona=0)

) as t
group by idpersona,diaslao,t.dias,t.meses,t.anios,emfechadesde
) as d

);


return 	true;
END;
$function$
