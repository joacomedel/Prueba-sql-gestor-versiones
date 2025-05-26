CREATE OR REPLACE FUNCTION public.generarchequeanulado(bigint, integer, integer, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE


--select * from generarchequeanulado(6,17,1,26498504)

--  $1 chnumero $2 idcuentabancaria  $3 cantidad de cheques  $4  primernumero a anular
   rusuario record;
   datocheque record;
   primernumero bigint;
   elcheque bigint;
   ultimonumero bigint;
   elidcheque bigint;
   cantidadanular integer;
   centro integer;
   elidcentrocheque integer;
   i integer;
   datoschequera record;
   lachequera bigint;
   lacuentabancaria integer;

BEGIN
lachequera=$1;
primernumero=$4;
lacuentabancaria=$2;
cantidadanular=$3;
ultimonumero = primernumero+cantidadanular;



SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN
   rusuario.idusuario = 25;
END IF;


   SELECT into datoschequera chnumero as elchnumero ,*
   FROM chequera  LEFT JOIN cheque  
   using(idcuentabancaria,chnumero)
   NATURAL JOIN chequeratipo JOIN cuentabancariasosunc  
   on  (chequera.idcuentabancaria=cuentabancariasosunc.idcuentabancaria) 
   JOIN banco  on  (cuentabancariasosunc.idbanco=banco.idbanco)  
   WHERE  chnumero=lachequera and chequera.idcuentabancaria=lacuentabancaria; 


  

if found and (ultimonumero<=datoschequera.chnumerochequefin)then 

   i=0;

   while (primernumero+i<ultimonumero) loop

         --Creo el cheque
         INSERT INTO cheque (cdenominacion, cnumero,cmonto,cfechaconfeccion,idcuentabancaria,chnumero)
                 VALUES('S.O.S.U.N.C',primernumero+i,0,current_date,lacuentabancaria,lachequera);
                 elidcheque = currval('cheque_idcheque_seq');
                 elidcentrocheque = centro();
         
         --Lo creo en estado anulado
         INSERT INTO    
         chequeestado(cefechaini,idchequeestadotipo,idcheque,idcentrocheque,idusuario,cecomentario)
         VALUES(now(),3,elidcheque,elidcentrocheque,rusuario.idusuario,'  Generado anulado desde sp 
         generarchequeanulado() ');

          update chequera set chnumerochequesig=chnumerochequesig+1
          WHERE  chnumero=lachequera and chequera.idcuentabancaria=lacuentabancaria;
     i=i+1;
   END loop;


end if ;



return true;
END;

$function$
