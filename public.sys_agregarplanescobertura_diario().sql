CREATE OR REPLACE FUNCTION public.sys_agregarplanescobertura_diario()
 RETURNS void
 LANGUAGE plpgsql
AS $function$/*Verifica que el estado se corresponda con el que deberia tener segun su fechafinos, en caso de no se
un esdo valido, se actualiza al estado valido.


*/
DECLARE
  

BEGIN


ALTER TABLE afilsosunc DISABLE TRIGGER disparadordespuesmodificarafilsosunc;
ALTER TABLE benefsosunc DISABLE TRIGGER disparadordespuesmodificarbenefsosunc;
ALTER TABLE benefreci DISABLE TRIGGER disparadordespuesmodificarbenefreci;
ALTER TABLE afilreci DISABLE TRIGGER disparadordespuesmodificarafilreci;

--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 30;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 31;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 32;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 33 OR barra = 34 OR barra = 35 OR barra = 36;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 37;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra < 30 ;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra > 100 AND fechafinos >= current_date ;

PERFORM agregarpersonaplanes_contabla(nrodoc,tipodoc) FROM persona where barra = 30;
PERFORM agregarpersonaplanes_contabla(nrodoc,tipodoc) FROM persona where barra = 31;
PERFORM agregarpersonaplanes_contabla(nrodoc,tipodoc) FROM persona where barra = 32;
PERFORM agregarpersonaplanes_contabla(nrodoc,tipodoc) FROM persona where barra = 33 OR barra = 34 OR barra = 35 OR barra = 36;
PERFORM agregarpersonaplanes_contabla(nrodoc,tipodoc) FROM persona where barra = 37;
PERFORM agregarpersonaplanes_contabla(nrodoc,tipodoc) FROM persona where barra < 30 ;
PERFORM agregarpersonaplanes_contabla(nrodoc,tipodoc) FROM persona where barra > 100 AND fechafinos >= current_date ;

--MaLaPi 31-08-2022 Lo agrego para que asigne un plan de cobertura a las personas segun su consumo de los ultimos años
PERFORM afiliaciones_asignarcentroregional();


ALTER TABLE afilsosunc ENABLE TRIGGER disparadordespuesmodificarafilsosunc;
ALTER TABLE benefsosunc ENABLE TRIGGER disparadordespuesmodificarbenefsosunc;
ALTER TABLE benefreci ENABLE TRIGGER disparadordespuesmodificarbenefreci;
ALTER TABLE afilreci ENABLE TRIGGER disparadordespuesmodificarafilreci;

END;





$function$
