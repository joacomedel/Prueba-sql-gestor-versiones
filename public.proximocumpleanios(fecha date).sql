CREATE OR REPLACE FUNCTION public.proximocumpleanios(fecha date)
 RETURNS date
 LANGUAGE plpgsql
AS $function$declare
	cumplesig date;
begin
if nullvalue(fecha) then
   fecha =  to_date(concat(extract(year from to_date(current_date,'YYYY-MM-DD')) ,'-', '01'  ,'-', '01'),'YYYY-MM-DD');
end if;
if extract(month from to_date(fecha,'YYYY-MM-DD')) = 2 and extract(day from to_date(fecha,'YYYY-MM-DD')) = 29 then 
	if not bisiesto(extract(year from current_date)::int) then
		cumplesig = DATE (concat(extract(year from to_date(current_date,'YYYY-MM-DD')) ,'-03-01'));
		if(cumplesig < current_date) then
				if not bisiesto((extract(year from current_date)+1)::int) then
					cumplesig = DATE (concat(extract(year from to_date(current_date,'YYYY-MM-DD'))+1  ,'-03-01'));
				else
					cumplesig = DATE (concat(extract(year from to_date(current_date,'YYYY-MM-DD'))+1  ,'-', extract(month from to_date(fecha,'YYYY-MM-DD'))  ,'-', extract(day from to_date(fecha,'YYYY-MM-DD'))));
				end if;
		end if;
		
	else
		cumplesig = DATE (concat(extract(year from to_date(current_date,'YYYY-MM-DD'))  ,'-', extract(month from to_date(fecha,'YYYY-MM-DD'))  ,'-', extract(day from to_date(fecha,'YYYY-MM-DD'))));
		if(cumplesig < current_date) then
				if not bisiesto((extract(year from current_date)+1)::int) then
					cumplesig = DATE (concat(extract(year from to_date(current_date,'YYYY-MM-DD'))+1  ,'-03-01'));
				else
					cumplesig = DATE (concat(extract(year from to_date(current_date,'YYYY-MM-DD'))+1  ,'-', extract(month from to_date(fecha,'YYYY-MM-DD'))  ,'-', extract(day from to_date(fecha,'YYYY-MM-DD'))));
				end if;
		end if;
	end if;
else
/*Dani modifico el 26-06-2015 el DATE por el to_date*/
	cumplesig = to_date (concat(extract(year from to_date(current_date,'YYYY-MM-DD')) ,'-', extract(month from to_date(fecha,'YYYY-MM-DD'))  ,'-', extract(day from to_date(fecha,'YYYY-MM-DD'))),'YYYY-MM-DD');
            if(cumplesig < current_date) then
                         cumplesig = to_date (concat(extract(year from to_date(current_date,'YYYY-MM-DD'))+1  ,'-', extract(month from to_date(fecha,'YYYY-MM-DD'))  ,'-', extract(day from to_date(fecha,'YYYY-MM-DD'))),'YYYY-MM-DD');
            end if;
end if;
return cumplesig;
end;
$function$
