CREATE OR REPLACE FUNCTION public.crearpadron(date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Recibe como parametros la fecha a la que hay que generar el padron
*/
DECLARE
       pfechaentrada alias for $1;
       caru3meses integer;
       pfecha date;
       
BEGIN

SELECT INTO pfecha pfechaentrada - interval '13 month';
--MaLaPi 23-07-2021 Ya no se elimina, solo se borra
--DROP TABLE padronsosunc;
--MaLaPi 27-07-2021 Por correo de Carolina:  tal lo charlado con la Presidente de la Obra Social y en concordancia con el Estatuto de SOSUNC y el Reglamento Electoral, solo podrán votar los Afiliados --Obligatorios, por lo tanto habría que sacar del padrón a los afiliados jubilados ya que pertenecen al grupo de adherentes.

caru3meses = 0;
DELETE FROM padronsosunc;

INSERT INTO padronsosunc (barra,nrodoc,tipodoc,nombres,apellido,seaplicapadron,iddepen,deben)  (
SELECT barra,nrodoc,descrip as tipodoc,nombres,apellido
,  CASE WHEN  barra ='35' THEN 'Adherente' ELSE  seaplicapadron END 
,  CASE WHEN  barra ='35' THEN 'AD' ELSE  iddepen END  
,CASE WHEN nullvalue(optan) THEN 'NO opta' ELSE 'Opta' END as deben
FROM persona
NATURAL JOIN tiposdoc
LEFT JOIN 
(
 SELECT nrodoc,tipodoc,max(idcargo) as idcargo,seaplicapadron
   FROM cargo
   NATURAL JOIN padroncategorias
   WHERE fechafinlab >= pfecha
   GROUP BY nrodoc,tipodoc,seaplicapadron
   ORDER BY nrodoc,tipodoc,seaplicapadron
  ) as cargovigente USING(nrodoc,tipodoc)
LEFT JOIN (
 SELECT nrodoc,tipodoc,Count(*) as cantidadaportes
  FROM (
        SELECT ano,mes,nrodoc,tipodoc
        FROM aporte
        JOIN cargo ON aporte.idlaboral = cargo.idcargo
        WHERE fechafinlab >= pfecha AND fechaingreso>=pfecha
        group by ano,mes,nrodoc,tipodoc
        )as t
  group by nrodoc,tipodoc
  having count(*)>12
  UNION
  SELECT nrodoc,tipodoc,Count(*) as cantidadaportes
        FROM (
        SELECT ano,mes,nrodoc,tipodoc
        FROM aporte
        JOIN afiljub ON aporte.idlaboral = afiljub.idcertpers
        and fechaingreso>=pfecha
        group by ano,mes,nrodoc,tipodoc
        )as t
        group by nrodoc,tipodoc
        having count(*)>=12
        UNION -- becarios
        SELECT nrodoc,tipodoc,Count(*) as cantidadaportes
        FROM (
           SELECT ano,mes,nrodoc,tipodoc
           FROM aporte NATURAL JOIN afilibec
           WHERE
                fechaingreso>=pfecha
           group by ano,mes,nrodoc,tipodoc
      )as t
      group by nrodoc,tipodoc
      having count(*)>=12
) as continuidadanio USING(nrodoc,tipodoc)
 LEFT JOIN cargo USING(idcargo,nrodoc,tipodoc)
 LEFT JOIN (
 Select nrodoc,tipodoc,count(*) as optan 
FROM (
   
   SELECT nrodoc,tipodoc,max(idcargo) as idcargo,seaplicapadron
   FROM cargo
   NATURAL JOIN padroncategorias
   WHERE fechafinlab >= pfecha AND cargo.fechafinlab >= pfecha
   GROUP BY nrodoc,tipodoc,seaplicapadron
   )  as t
GROUP BY nrodoc,tipodoc
HAVING count(*) > 1
 ) as tienenqueoptar USING (nrodoc,tipodoc)
 WHERE  --- barra <> 35 AND    comento VAS 02/09/24 para incorporar al padrón a los jubilados
        fechafinos >= pfecha AND 
 not nullvalue(continuidadanio.cantidadaportes)
ORDER BY iddepen,seaplicapadron
);

return caru3meses;

end;
$function$
