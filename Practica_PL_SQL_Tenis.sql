/* 2025_v1 */

drop table reservas;
drop table pistas;
drop sequence seq_pistas;

create table pistas (
	nro integer primary key
	);
	
create table reservas (
	pista integer references pistas(nro),
	fecha date,
	hora integer check (hora >= 0 and hora <= 23),
	socio varchar(20),
	primary key (pista, fecha, hora)
	);
	
create sequence seq_pistas;

insert into pistas values (seq_pistas.nextval);
insert into reservas 
	values (seq_pistas.currval, '20/03/2018', 14, 'Pepito');
insert into pistas values (seq_pistas.nextval);
insert into reservas 
	values (seq_pistas.currval, '24/03/2018', 18, 'Pepito');
insert into reservas 
	values (seq_pistas.currval, '21/03/2018', 14, 'Juan');
insert into pistas values (seq_pistas.nextval);
insert into reservas 
	values (seq_pistas.currval, '22/03/2018', 13, 'Lola');
insert into reservas 
	values (seq_pistas.currval, '22/03/2018', 12, 'Pepito');

commit;

create or replace function anularReserva( 
	p_socio varchar,
	p_fecha date,
	p_hora integer, 
	p_pista integer ) 
return integer is

begin
	DELETE FROM reservas 
        WHERE
            trunc(fecha) = trunc(p_fecha) AND
            pista = p_pista AND
            hora = p_hora AND
            socio = p_socio;

	if sql%rowcount = 1 then
		commit;
		return 1;
	else
		rollback;
		return 0;
	end if;
end;
/

create or replace FUNCTION reservarPista(
        p_socio VARCHAR,
        p_fecha DATE,
        p_hora INTEGER
    ) 
RETURN INTEGER IS

    CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas 
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE 
                trunc(fecha) = trunc(p_fecha) AND
                hora = p_hora)
        order by nro;
            
    vPista INTEGER;

BEGIN
    OPEN vPistasLibres;
    FETCH vPistasLibres INTO vPista;

    IF vPistasLibres%NOTFOUND
    THEN
        CLOSE vPistasLibres;
        RETURN 0;
    END IF;

    INSERT INTO reservas VALUES (vPista, p_fecha, p_hora, p_socio);
    CLOSE vPistasLibres;
    COMMIT;
    RETURN 1;
END;
/

/*
SET SERVEROUTPUT ON
declare
 resultado integer;
begin
 
     resultado := reservarPista( 'Socio 1', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;
     
     --Continua tu solo....
     
      
    resultado := anularreserva( 'Socio 1', CURRENT_DATE, 12, 1);
     if resultado=1 then
        dbms_output.put_line('Reserva 1 anulada: OK');
     else
        dbms_output.put_line('Reserva 1 anulada: MAL');
     end if;
  
     resultado := anularreserva( 'Socio 1', date '1920-1-1', 12, 1);
     --Continua tu solo....
  
end;
/
*/

-- Paso 1: Leer el código fuente de ambas funciones investigando las siguientes cuestiones:
/*
1.P.- ¿Por qué en las comparaciones de fecha en Oracle conviene utilizar la función trunc?
1.R.- Al utilizar la función trunc sobre un tipo de dato Date lo que provoca es quedarse únicamente con el valor de la fecha (día, mes y año), descartando de esta forma los valores de horas, minutos y segundos.
	De este modo, al comparar fechas haciendo uso de la función trunc, únicamente compara los días sin tener en cuenta las horas.
	Esto podría provocar que varios registros coincideran con el valor de día de la parte izquierda, recuperando más registros (por exisitir varios registros con el mismo día pero con distintas horas).
*/
/*
2.P.- ¿Qué es sql%rowcount y cómo funciona?
2.R.- Es un atributo de cursor que Oracle gestiona automáticamente. Mantiene el recuento del número de filas que han sido procesadas por la última sentencia SQL (INSERT, UPDATE, DELETE o SELECT).
	Después de ejecutar una sentencia SQL (por ejemplo, un UPDATE que modifica varias filas), Oracle actualiza el valor de SQL%ROWCOUNT para almacenar el número de filas que se han visto afectadas.
*/
/*
3.1.P.- ¿Qué es una variable de tipo cursor?
3.1.R.- Es una variable especial que se utiliza para almacenar una referencia a un cursor.
3.2.P.- ¿Qué variable de tipo cursor hay en la segunda función?
3.2.R.- La variable de tipo cursor es vPistasLibres
3.3.P.- ¿Qué efecto tienen las operaciones open, fetch y close?
3.3.R.- La operación open ejecuta la consulta asociada al cursor, fetch obtiene los datos del cursor, y close libera o cierra el conjunto de filas del cursor.
3.4.P.- ¿Qué valores toman las propiedades de cursor FOUND y NOTFOUND y en qué caso?
3.4.R.- FOUND devuelve TRUE si la última operación FETCH recuperó al menos una fila y FALSE si no recuperó ninguna. Devuelve NULL si no se ha realizado ninguna operación FETCH o si el cursor no está abierto.
	NOTFOUND devuelve TRUE si la última operación FETCH no recuperó ninguna fila y False si recupera al menos una. Devuelve NULL si el cursor no devuelve filas cuando se abre (open).
*/
/*
4.P.- En la función anularReserva discute si da lo mismo sustituir el rollback por un commit y por qué
4.R.- No, no da lo mismo. Inicialmente se lanza una sentencia de borrado, si como consecuencia de ello se borra un registro, se comita y sale, pero si se han borrado más de un registro (o ninguno) entonces hace rollback,
	es decir, deshace el cambio porque está pensado para borrar un único registro.
*/
