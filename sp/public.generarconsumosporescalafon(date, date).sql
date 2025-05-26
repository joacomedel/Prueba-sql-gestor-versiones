CREATE OR REPLACE FUNCTION public.generarconsumosporescalafon(date, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE
       fdesde date;
       fhasta date;

BEGIN

     /** Limpio las tablas que van a contener los ingresos y costos **/
     DELETE  FROM ingresoaportejubpen;
     DELETE  FROM costojubpen;

     /* ingreso la informacion a las tablas */
     fdesde = $1;
     fhasta = $2;
     /* Inserto a los JUB y PEN*/
      INSERT INTO ingresoaportejubpen (nrodoc,tipodoc,aportodesde,importe,barra)   (
             SELECT nrodoc, tipodoc, MIN(fechainiaport)as aportdesde,SUM(importe) as aporto, barra
             FROM aportejubpen
             NATURAL JOIN persona
             WHERE  fechainiaport >= fdesde   -- Lo que aporto desde la fecha desde
             GROUP by tipodoc,nrodoc, barra
       );
     /* Inserto a los beneficiarios de los JUB y PEN*/

      INSERT INTO ingresoaportejubpen (nrodoc,tipodoc,aportodesde,importe,barra)   (
             SELECT persona.nrodoc,persona.tipodoc,aportodesde,importe,persona.barra
             FROM ingresoaportejubpen as T
             JOIN benefsosunc on (benefsosunc.nrodoctitu= T.nrodoc and  benefsosunc.tipodoctitu = T.tipodoc)
             JOIN persona ON (benefsosunc.nrodoc = persona.nrodoc and  benefsosunc.tipodoc = persona.tipodoc)
      );
       /* Consumos en prestaciones*/
       INSERT INTO costojubpen (tipodoc,nrodoc,barra,costososunc,fechagasto,costojubpendescripcion)(
              SELECT tipodoc,nrodoc, barra,SUM(importesorden.importe) as costoprestaciones,fechaemision::date,'Orden'
              FROM consumo
              NATURAL JOIN orden
              NATURAL JOIN importesorden
              JOIN ingresoaportejubpen using (nrodoc,tipodoc)
              NATURAL JOIN persona
              WHERE fechaemision >= aportodesde and fechaemision <= fhasta -- Lo que consumio hasta la fecha fhasta
              GROUP by tipodoc,nrodoc, barra, fechaemision,nroorden,centro
       );

       /*Consumos Farmacia */
       INSERT INTO costojubpen (tipodoc,nrodoc,barra,costososunc,fechagasto,costojubpendescripcion)(
              SELECT  tipodoc,nrodoc, barra,importeapagar as costofarmacia,fechaemision::date,'Farmacia'
              FROM recetarioitem
              NATURAL JOIN recetario
              JOIN ingresoaportejubpen using (nrodoc,tipodoc)
              NATURAL JOIN persona
              WHERE fechaemision >= aportodesde and fechaemision <= fhasta -- Lo que consumio hasta la fecha fhasta
       );



       /*Costo reintegros*/
       INSERT INTO costojubpen (tipodoc,nrodoc,barra,costososunc,fechagasto,costojubpendescripcion)(
              SELECT  tipodoc,nrodoc, barra,rimporte as costoreintegro,rfechaingreso::date,'Reintegros'
              FROM reintegro
              JOIN ingresoaportejubpen using (nrodoc,tipodoc)
              NATURAL JOIN persona
              WHERE rfechaingreso >= aportodesde and not nullvalue(rimporte) and rfechaingreso <= fhasta -- Lo que consumio hasta la fecha fhasta
       );



       /* COSTO DERVACIONES */
        INSERT INTO costojubpen (tipodoc,nrodoc,barra,costososunc,fechagasto,costojubpendescripcion)(
               SELECT  tipodoc,nrodoc, barra,importederiv as costoderivacion,dfechaingreso::date,'Derivaciones'
                FROM (
               SELECT dvimportetotal as importederiv ,nrodoc,tipodoc,dfechaingreso
               FROM derivacion
               NATURAL JOIN derivacionviatico
               UNION
               SELECT damportetotal as importederiv ,nrodoc,tipodoc,dfechaingreso
               FROM derivacion
               NATURAL JOIN derivacionalojamiento
               UNION
               SELECT dtimportereconocido as importederiv ,nrodoc,tipodoc,dfechaingreso
               FROM derivacion
               NATURAL JOIN derivaciontransporte
               UNION
               SELECT  dvimportetotal as importederiv ,nrodoc,tipodoc,dfechaingreso
               FROM derivacion
               NATURAL JOIN derivacionviatico

               )as costoderivacion
      JOIN ingresoaportejubpen using (nrodoc,tipodoc)
      NATURAL JOIN persona
      WHERE dfechaingreso >= aportodesde and dfechaingreso <= fhasta -- Lo que consumio hasta la fecha fhasta
      );


return true;
END;
$function$
