CREATE OR REPLACE FUNCTION public.generarordenpago()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Genera una orden para pagar un conjunto de prestaciones.*/

DECLARE
	imputaciones refcursor;
	unaimp RECORD;
	unaordenpago RECORD;
	laorden bigint;
	resultado boolean;
        imptotal DOUBLE PRECISION;
rusuario record;
elidusuario integer;
BEGIN
     imptotal =0;
      IF not existecolumtemp('tempordenpago', 'idordenpagotipo') THEN 
          ALTER TABLE tempordenpago ADD COLUMN idordenpagotipo integer DEFAULT 1;
      END IF; 
     
      IF not existecolumtemp('tempordenpago', 'nrocuentachaber') THEN 
          ALTER TABLE tempordenpago ADD COLUMN nrocuentachaber VARCHAR;
      END IF; 

     SELECT INTO unaordenpago * FROM tempordenpago;
     IF nullvalue(unaordenpago.nroordenpago) THEN
        SELECT INTO laorden nextval('ordenpago_seq')  ;
        UPDATE tempordenpagoimputacion SET nroordenpago = laorden;
        UPDATE tempordenpago SET nroordenpago = laorden;
        SELECT INTO unaordenpago * FROM tempordenpago;
     ELSE
           laorden = unaordenpago.nroordenpago;
     END IF;
     
     
     /*Inserto la Orden de pago con estado 1 - Pendiente*/
/* Se guarda la informacion del usuario que genero el comprobante */
    SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
    IF not found THEN
             elidusuario = 25;
    ELSE
        elidusuario = rusuario.idusuario;
    END IF;

     INSERT INTO ordenpago (nroordenpago,idcentroordenpago,fechaingreso,beneficiario,concepto,importetotal, idordenpagotipo,nrocuentachaber)
            VALUES (unaordenpago.nroordenpago,centro(),unaordenpago.fechaingreso,unaordenpago.beneficiario,unaordenpago.concepto,unaordenpago.importetotal
,unaordenpago.idordenpagotipo,unaordenpago.nrocuentachaber);
       

   INSERT INTO cambioestadoordenpago (fechacambio,nroordenpago,idcentroordenpago,idtipoestadoordenpago,motivo, idusuario)
            VALUES(CURRENT_DATE,unaordenpago.nroordenpago,centro(),1,'Generada desde generarordenpago ',elidusuario);
     /*Inserto las imputaciones de la Orden de Pago*/
     OPEN imputaciones FOR SELECT sum(debe) as debe, codigo,nroordenpago,sum(haber) as haber 
                           FROM tempordenpagoimputacion 
                           GROUP BY codigo,nroordenpago;

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
