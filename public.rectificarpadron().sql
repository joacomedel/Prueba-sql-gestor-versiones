CREATE OR REPLACE FUNCTION public.rectificarpadron()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
begin
insert into tpadronelectoral select * from tpadronelectoralinclusion;
update tpadronelectoral set claustro=31 where nrodoc='27832293';
update tpadronelectoral set claustro=31 where nrodoc='16889994';
delete from tpadronelectoral where nrodoc='21785047';
update tpadronelectoral set claustro=31, dependencia='FACULTAD DE CIENCIAS AGRARIAS', localidad='CINCO SALTOS' where nrodoc='06382415';
update tpadronelectoral set claustro=31, dependencia='FACULTAD DE CIENCIAS AGRARIAS', localidad='CINCO SALTOS' where nrodoc='07963547';
update tpadronelectoral set claustro=31, dependencia='FACULTAD DE DERECHOS Y CIENCIAS SOCIALES', localidad='GENERAL ROCA' where nrodoc='08213101';

update tpadronelectoral set claustro=30, dependencia='FACULTAD DE INGENIERÍA', localidad='NEUQUEN' where nrodoc='05951370';
update tpadronelectoral set claustro=30, dependencia='FACULTAD DE INGENIERÍA', localidad='NEUQUEN' where nrodoc='13404981';
update tpadronelectoral set claustro=30, dependencia='FACULTAD DE INGENIERÍA', localidad='NEUQUEN' where nrodoc='17238726';
update tpadronelectoral set claustro=30, dependencia='FACULTAD DE INGENIERÍA', localidad='NEUQUEN' where nrodoc='16120304';
update tpadronelectoral set claustro=30, dependencia='FACULTAD DE INGENIERÍA', localidad='NEUQUEN' where nrodoc='14916303';

update tpadronelectoral set claustro=31, dependencia='FACULTAD DE HUMANIDADES', localidad='NEUQUEN' where nrodoc='06819116';
update tpadronelectoral set claustro=30, dependencia='FACULTAD DE TURISMO', localidad='NEUQUEN' where nrodoc='22012291';
update tpadronelectoral set claustro=31, dependencia='CENTRO UNIVERSITARIO REGIONAL BARILOCHE', localidad='SAN CARLOS DE BARILOCHE' where nrodoc='16053882';
update tpadronelectoral set claustro=30 where nrodoc='17748289';
update tpadronelectoral set claustro=31 where nrodoc='16122685';
update tpadronelectoral set claustro=31 where nrodoc='27431179';
delete from tpadronelectoral where nrodoc='07518419';
delete from tpadronelectoral where nrodoc='14692111';
update tpadronelectoral set claustro = 31 where nrodoc='17748289';

/*update tpadronelectoral set dependencia='CENTRO UNIVERSITARIO REGIONAL ZONA ATLANTICA', localidad='VIEDMA' where nrodoc='24207458';
update tpadronelectoral set dependencia='CENTRO UNIVERSITARIO REGIONAL BARILOCHE', localidad='SAN CARLOS DE BARILOCHE' where nrodoc='16872033';
update tpadronelectoral set dependencia='FACULTAD DE DERECHOS Y CIENCIAS SOCIALES', localidad = 'GENERAL ROCA' where nrodoc='20934525';
update tpadronelectoral set dependencia='INSTITUTO DE BIOLOGIA MARINA Y PESQUERA ALTE. STORNI', localidad='SAN ANTONIO OESTE' where nrodoc='12262213';
update tpadronelectoral set dependencia='ASENTAMIENTO UNIVERSITARIO VILLA REGINA', localidad='VILLA REGINA' where nrodoc='08216583';*/

return 'true';
end;
$function$
