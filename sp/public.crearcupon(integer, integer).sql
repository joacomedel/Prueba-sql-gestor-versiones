CREATE OR REPLACE FUNCTION public.crearcupon(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	
        cursordatoscupon REFCURSOR;
	datocupon RECORD;
	datosafil record;
        datoscupones record;
        resp boolean;
        elnrodoc INTEGER;
	eltipodoc INTEGER;
	elidtarjeta INTEGER;
	elidcentrotarjeta INTEGER;
	elidcuponnuevo INTEGER;
        lafechafin date;


BEGIN
     elidtarjeta =$1;
     elidcentrotarjeta =$2;
     ---- Al crear un nuevo cupon hay que dar de baja al que esta en circulacion

     -- Busco el cupon del afiliado que se encuentra en circulacion (que no fue dada de baja idestadotipo <> 4; )
 OPEN cursordatoscupon FOR SELECT *
       
     FROM  cupon
     NATURAL JOIN  cuponestado
     WHERE idtarjeta=elidtarjeta and idcentrotarjeta=elidcentrotarjeta and nullvalue(cefechafin) and idestadotipo <> 4;

    -- Si hay un cupon en circulacion la doy de baja

     FETCH cursordatoscupon into datoscupones;
	       WHILE found LOOP
        SELECT INTO resp cambiarestadocupon(datoscupones.idcupon,datoscupones.idcentrocupon,4);
      FETCH cursordatoscupon into datoscupones;
     END loop;
close cursordatoscupon;
     
    SELECT INTO datosafil *
    FROM persona
    NATURAL JOIN tarjeta
    WHERE idtarjeta=elidtarjeta and idcentrotarjeta=elidcentrotarjeta;
	
 
--Modifico Dani el 11-06-2014 por pedido de Crisitian R. para q a los jubilados le emita el --cupon con la fechafinos actual y no la incrementada en 30 dias
if (false and datosafil.barra=35) then 

       lafechafin= case when (EXTRACT(MONTH FROM (datosafil.fechafinos))=12 ) then 
	to_date(
    concat(EXTRACT(YEAR FROM (datosafil.fechafinos)::timestamp)+1 ,'-',01,'-10'),'YYYY-MM-DD')
        else  to_date(concat(EXTRACT(YEAR FROM (datosafil.fechafinos)::timestamp) ,'-',EXTRACT(MONTH FROM
        (datosafil.fechafinos))+1,'-10') ,'YYYY-MM-DD')   end  ;
else 
	lafechafin=datosafil.fechafinos;	
end if;		

			



    INSERT INTO cupon (idtarjeta,idcentrotarjeta,cfechavto )VALUES (elidtarjeta,elidcentrotarjeta,lafechafin);



    elidcuponnuevo =  currval('cupon_idcupon_seq');
    SELECT INTO resp cambiarestadocupon(elidcuponnuevo,centro(),1);


RETURN 'true';
END;
$function$
