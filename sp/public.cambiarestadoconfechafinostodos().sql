CREATE OR REPLACE FUNCTION public.cambiarestadoconfechafinostodos()
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

 -- MaLaPi 06-11-2017 Genero el Historico de Afiliados de la Obra Social

INSERT INTO afiliaciones_histafiliados (SELECT t.*
FROM (
select persona.nrodoc,apellido,nombres,fechanac,sexo,estcivil,fechainios,fechafinos,iddireccion,persona.tipodoc,carct,persona.barra,idcentrodireccion,nrodocreal
,benefsosunc.nrodoctitu as nrodoctitusosunc,benefsosunc.tipodoctitu as tipodoctitusosunc
,benefreci.nrodoctitu as nrodoctitureci,benefreci.tipodoctitu as tipodoctitureci
,now() as fechaingreso
,25 as idusuario
,extract('year' from now()) as anioingreso
,extract('month' from now()) as mesingreso
from persona
LEFT JOIN benefsosunc USING(nrodoc,tipodoc)
LEFT JOIN benefreci USING(nrodoc,tipodoc)
where fechafinos >= current_date 
order by barra
) as t
LEFT JOIN afiliaciones_histafiliados USING(nrodoc,tipodoc,anioingreso,mesingreso)
WHERE nullvalue(afiliaciones_histafiliados.nrodoc)
);

--Dani agrego 09022023 para q se deje corriendo automaticamente el sp pero no de de baja los vtos de los jubilados
    PERFORM   cambiarestadoconfechafinos('persona.barra > 29 and persona.barra < 100 and persona.barra <>35');
  
    PERFORM   cambiarestadoconfechafinos('persona.barra > 129');

 


--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 30;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 31;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 32;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 33 OR barra = 34 OR barra = 35 OR barra = 36;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra = 37;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra < 30 ;
--PERFORM agregarpersonaplanes(nrodoc,tipodoc) FROM persona where barra > 100 AND fechafinos >= current_date ;
--MaLapi 24-08-2018 comento de aqui, puesto que ya se implemento en procesos automaticos. Se puede correr desde los procesos sys_agregarplanescobertura_diario y sys_agregarplanescobertura_mensual



ALTER TABLE afilsosunc ENABLE TRIGGER disparadordespuesmodificarafilsosunc;
ALTER TABLE benefsosunc ENABLE TRIGGER disparadordespuesmodificarbenefsosunc;
ALTER TABLE benefreci ENABLE TRIGGER disparadordespuesmodificarbenefreci;
ALTER TABLE afilreci ENABLE TRIGGER disparadordespuesmodificarafilreci;

END;





$function$
