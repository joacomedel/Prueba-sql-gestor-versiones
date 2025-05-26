CREATE OR REPLACE FUNCTION public.insertarbarrareciprocidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	benefBD RECORD;
	benefT RECORD;
	barrasBD RECORD;
        
	barrita RECORD;
	proxima integer;
	terminacion boolean;

        barrastemp RECORD;	

BEGIN

terminacion='true';

SELECT INTO benefT * FROM bene;
SELECT INTO barrasBD * FROM barras natural join persona WHERE  benefT.tipodoc = tipodoc AND benefT.nrodoc = nrodoc ;

IF NOT FOUND
	then
		IF benefT.idvin=1 
			then 
				INSERT INTO barras VALUES (101,1,benefT.tipodoc,benefT.nrodoc) ;
		END IF;
		IF benefT.idvin=4 
			then 
			INSERT INTO barras VALUES (121,1,benefT.tipodoc,benefT.nrodoc);
		 END IF;
		IF benefT.idvin=5 
			then 
				INSERT INTO barras VALUES (122,1,benefT.tipodoc,benefT.nrodoc);
		END IF;
		IF benefT.idvin <> 1 AND  benefT.idvin <> 4
				AND  benefT.idvin <> 5 THEN
			
				SELECT INTO barrita * FROM tbarras WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
					proxima=barrita.siguiente;
					proxima = proxima +100;
				 INSERT INTO barras VALUES (proxima,1,benefT.tipodoc,benefT.nrodoc);
				 proxima = proxima - 99;
				 UPDATE tbarras SET siguiente=proxima WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;	

		END IF; 
	
	else
	
		IF barrasBD.barra=101 
			then 
                                IF benefT.idvin=1 
			        then
                                  
				     UPDATE barras SET prioridad='1'
                                        WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc AND barrasBD.barra=barra  ; 
		                 
                               END IF;
				IF benefT.idvin=4 
					then 
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=121
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc  AND barrasBD.barra=barra;	
				END IF;
				IF benefT.idvin=5 
					then 
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=122
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc  AND barrasBD.barra=barra;	
				END IF;
				IF benefT.idvin <> 1 AND benefT.idvin <> 4
				AND  benefT.idvin <> 5 THEN
						SELECT INTO barrita * FROM tbarras WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
						proxima=barrita.siguiente;
						UPDATE  tbarras 
							SET 
								nrodoctitu=benefT.nrodoctitu,
								tipodoctitu=benefT.tipodoctitu,
								siguiente=proxima+1
						WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu ;
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=proxima+100
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc  AND barrasBD.barra=barra;	
				END IF; 
		END IF;
		
		IF barrasBD.barra=121 
			then 
				IF benefT.idvin=1 
					then 
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=101
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc  AND barrasBD.barra=barra;	
				END IF;
				IF benefT.idvin=5 
					then 
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=122
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc  AND barrasBD.barra=barra;	
				END IF;
				IF benefT.idvin <> 1 AND  benefT.idvin <> 5 THEN
						SELECT INTO barrita * FROM tbarras WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
						proxima=barrita.siguiente;
						UPDATE tbarras 
							SET 
								nrodoctitu=benefT.nrodoctitu,
								tipodoctitu=benefT.tipodoctitu,
								siguiente=proxima+1
						WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=proxima+100
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc   AND barrasBD.barra=barra;	
				END IF; 				
		END IF;
		
		IF barrasBD.barra=122 
			then 
				IF benefT.idvin=1 
					then 
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=101
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc  AND barrasBD.barra=barra;	
				END IF;
				IF benefT.idvin=4 
					then 
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=121
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc AND barrasBD.barra=barra;	
				END IF;
				IF benefT.idvin <> 1 AND  benefT.idvin <> 4
				THEN
						SELECT INTO barrita * FROM tbarras WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
						proxima=barrita.siguiente;
						UPDATE tbarras 
							SET 
								nrodoctitu=benefT.nrodoctitu,
								tipodoctitu=benefT.tipodoctitu,
								siguiente=proxima+1
						WHERE nrodoctitu=benefT.nrodoctitu AND tipodoctitu=benefT.tipodoctitu;
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=proxima+100
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc AND barrasBD.barra=barra;	
				END IF;
		END IF;
			
		IF (barrasBD.barra>=102) and (barrasBD.barra<=120) 
			then 
				IF benefT.idvin=1 
					then 
                                          
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=101
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc AND barrasBD.barra=barra;	
				              
                                END IF;
				IF benefT.idvin=4 
					then 
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=121
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc AND barrasBD.barra=barra;	
				END IF;
				IF benefT.idvin=5 
					then 
						UPDATE barras 
							SET 
								nrodoc=benefT.nrodoc,
								tipodoc=benefT.tipodoc,
								prioridad=1,
								barra=122
						WHERE nrodoc=benefT.nrodoc AND tipodoc=benefT.tipodoc  AND barrasBD.barra=barra;	
				END IF;
		END IF;	
			
		IF barrasBD.barra >= 130
			then
			 	terminacion='false';
		END IF;
		
END IF;

return terminacion;

END;
$function$
