CREATE OR REPLACE FUNCTION public.generarordenpago1()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Genera una orden para pagar un conjunto de prestaciones.*/

DECLARE
	imputaciones refcursor;
	unaimp RECORD;
	unaordenpago RECORD;
	resultado boolean;
        imptotal DOUBLE PRECISION;
BEGIN
     imptotal =0;
     SELECT INTO unaordenpago * FROM tempordenpago;
     /*Inserto la Orden de pago con estado 1 - Pendiente*/
     INSERT INTO ordenpago (nroordenpago,fechaingreso,beneficiario,concepto,importetotal)
            VALUES (unaordenpago.nroordenpago,unaordenpago.fechaingreso,unaordenpago.beneficiario,unaordenpago.concepto,unaordenpago.importetotal);
     INSERT INTO cambioestadoordenpago (fechacambio,nroordenpago,idtipoestadoordenpago,motivo)
            VALUES(CURRENT_DATE,unaordenpago.nroordenpago,1,'Se pagaran los reintegros');
     /*Inserto las imputaciones de la Orden de Pago*/
     /*Modifica DAni 14-05-2014 para q se guarde el haber*/
     OPEN imputaciones FOR SELECT sum(debe) as debe, codigo,nroordenpago,haber 
                           FROM tempordenpagoimputacion 
                           GROUP BY codigo,nroordenpago,haber ;

     FETCH imputaciones INTO unaimp;
     WHILE  found LOOP
       INSERT INTO ordenpagoimputacion (codigo,nrocuentac,nroordenpago,idcentroordenpago,debe,haber)
              VALUES (unaimp.codigo,unaimp.codigo,unaimp.nroordenpago,centro(),unaimp.debe,unaimp.haber);
       imptotal= imptotal + unaimp.debe;
       FETCH imputaciones INTO unaimp;
     END LOOP;
     CLOSE imputaciones;
     resultado = 'true';
     RETURN resultado;
END;
$function$
