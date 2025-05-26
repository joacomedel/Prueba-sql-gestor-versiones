CREATE OR REPLACE FUNCTION public.arreglar_prorrogas_actasdef()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
declare
begin


ALTER TABLE prorroga
  ADD column idcentroregional integer default centro();

update prorroga set idcentroregional=1;

ALTER TABLE prorroga
  DROP CONSTRAINT claveprorroga;

ALTER TABLE prorroga
  ADD CONSTRAINT claveprorroga PRIMARY KEY(idprorr, idcentroregional);

perform actualizartablasincro('prorroga');

create table actasdefun_tempo as select distinct * from actasdefun;
delete from actasdefun;
insert into actasdefun select * from actasdefun_tempo;

ALTER TABLE actasdefun
  ADD CONSTRAINT actasdefun_pkey PRIMARY KEY(tipodoc,nrodoc);
  
perform agregarsincronizable('actasdefun');

end;

$function$
