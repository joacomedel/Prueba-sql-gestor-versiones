CREATE OR REPLACE FUNCTION public.redondeamoneda(double precision, integer)
 RETURNS real
 LANGUAGE plpgsql
AS $function$
--Function RutRedondeaMoneda(Cantidad: Currency; Decimales:integer):Currency;
DECLARE
puntInt int;
impcur double precision;
Decimales alias for $2;
Cantidad alias for $1;

Begin
impcur=abs(Cantidad);
puntint=impcur;

if (Decimales=0)
 then puntInt:=((PuntInt+5000) / 10000)*10000;
else if (Decimales=1)
        then PuntInt:=((Puntint+500) / 1000)*1000;
        else if (Decimales=2)
             then PuntInt:=((PuntInt+50) / 100)*100;
             else if (Decimales=3)
                  then PuntInt:=((puntInt+5) / 10)*10;
                  end if;
             end if;
        end if;
end if;

if Cantidad<0 then puntInt:= -puntInt;
end if;

return puntInt;

end;
$function$
