CREATE OR REPLACE TYPE notas_t AS OBJECT (
    nCodAsi NUMBER,
    nCurAsi NUMBER,
    nCurso NUMBER,
    nNota1Ev NUMBER,
    nNota2Ev NUMBER,
    nNotaFinal NUMBER
);

CREATE OR REPLACE TYPE tNOTAS AS VARRAY(10) OF notas_t;

CREATE OR REPLACE TYPE alumnos_t AS OBJECT (
    nNumMat NUMBER,
    dNomAlu VARCHAR2(100),
    dFecNac DATE,
    dFecIng DATE,
    NOTAS tNOTAS,
    
    MEMBER FUNCTION fGet_DatosAlumno RETURN VARCHAR2,  
    MEMBER FUNCTION Set_FechaIngreso(xFecha DATE) RETURN VARCHAR2,
    MEMBER FUNCTION Num_Asignaturas RETURN NUMBER,
    MEMBER PROCEDURE Asig_Suspensas (xFecha DATE),
    MEMBER PROCEDURE Notas_Curso (codigo NUMBER),
    MEMBER PROCEDURE Aprobado_Curso (codigo NUMBER),
    MEMBER PROCEDURE Aprobar_Eval,
    MEMBER PROCEDURE Alta_Notas (nota notas_t) 
);

CREATE TABLE ALUMNOS OF alumnos_t;
DROP TABLE ALUMNOS;

INSERT INTO ALUMNOS VALUES(1, 'MARIO', '26/04/1997', '20/09/2017', tNOTAS(notas_t(1, 1, 2017, 10, 10, 10),notas_t(1, 2, 2018, 9, 8, 9),notas_t(2, 1, 2017, 10, 8, 10)));
INSERT INTO ALUMNOS VALUES(2, 'SERGIO', '28/02/1992', '20/09/2017', tNOTAS(notas_t(1, 1, 2017, 8, 7, 8),notas_t(1, 2, 2018, 6, 10, 8),notas_t(2, 1, 2017, 10, 10, 10)));
INSERT INTO ALUMNOS VALUES(3, 'JOSE', '05/10/1995', '20/09/2017', tNOTAS(notas_t(1, 1, 2017, 10, 9, 10),notas_t(1, 2, 2018, 6, 10, 8),notas_t(2, 1, 2017, 10, 10, 10), notas_t(2, 2, 2018, 6, 6, 6)));  

-- Get_DatosAlumno que nos devuelve numero de la matricula, nombre, edad (en años)
-- de un alumno

SELECT P.fGet_DatosAlumno() FROM ALUMNOS P;

CREATE OR REPLACE TYPE BODY alumnos_t AS 

    -- Get_DatosAlumno que nos devuelve numero de la matricula, nombre, edad (en años)
    -- de un alumno
    MEMBER FUNCTION fGet_DatosAlumno RETURN VARCHAR2 IS
    edad NUMBER;
    
    BEGIN
        
        SELECT 
            trunc(months_between(to_date(to_char(SYSDATE, 'dd/mm/yyyy'),
            'dd/mm/yyyy'), to_date(to_char(SELF.dFecNac, 'dd/mm/yyyy'), 'dd/mm/yyyy'))/12) AS DATOS
            INTO edad
        FROM DUAL;
            
        RETURN SELF.nNumMat ||' '|| SELF.dNomAlu ||' '|| SELF.edad;      
    END;
    
    -- Set_FechaIngreso que nos permite modificar la Fecha de Ingreso de un alumno --
    
    MEMBER FUNCTION Set_FechaIngreso (xFecha DATE) RETURN VARCHAR2 IS
    BEGIN
        UPDATE ALUMNOS SET dFecIng = xFecha  WHERE nNumMat = SELF.nNumMat;
        RETURN 'FECHA DE INGRESO MODIFICADA A ' || xFecha;
    END Set_FechaIngreso;  
    
    -- Num_Asignaturas nos indica de cuantas asignaturas está matriculado un alumno --
    
    MEMBER FUNCTION Num_Asignaturas RETURN NUMBER IS   
    BEGIN       
        RETURN self.notas.COUNT;
    END;     
    
    -- Asig_Suspensas que nos muestra por pantalla los datos de las asignaturas suspensas
    -- de un alumno en un Curso académico
    
    MEMBER PROCEDURE Asig_Suspensas (xCurso DATE) IS  
    NOTAS notas_t;
    BEGIN    
        FOR i IN 1..self.NOTAS.COUNT LOOP
           IF (NOTAS(i).nCurso = xCurso) THEN
                IF(NOTAS(i).nNotaFinal < 5) THEN
                    DBMS_OUTPUT.PUT_LINE('CODIGO: '||NOTAS.nCodAsi || ' '
                    || 'CURSO: ' || NOTAS.nCurso || ' '|| 'CURSO ACADEMICO: ' 
                    || NOTAS.nCurAsi || ' ' || 'NOTA 1ºEVA: ' || NOTAS.nNota1Ev || ' '
                    || 'NOTA 2ºEVA: ' || NOTAS.nNota2Ev || ' '|| 'NOTA 3ºEVA: ' || NOTAS.nNotaFinal); 
                END IF;
           END IF;
        END LOOP;  
    END;    
    
    -- Notas_Curso que pasando como parámetro el código de curso nos muestra por
    -- pantalla las asignaturas del curso en las que está matriculado el alumno, así como las
    -- notas que ha obtenido en cada una de ellas
    
    MEMBER PROCEDURE Notas_Curso (xCurso NUMBER) IS
    NOTAS notas_t;
    BEGIN    
        FOR i IN 1..self.NOTAS.COUNT LOOP
           IF (NOTAS(i).nCurso = xCurso) THEN
                    DBMS_OUTPUT.PUT_LINE('CODIGO: '||NOTAS.nCodAsi || ' '
                    || 'CURSO: ' || NOTAS.nCurso || ' '|| 'CURSO ACADEMICO: ' 
                    || NOTAS.nCurAsi || ' ' || 'NOTA 1ºEVA: ' || NOTAS.nNota1Ev || ' '
                    || 'NOTA 2ºEVA: ' || NOTAS.nNota2Ev || ' '|| 'NOTA 3ºEVA: ' || NOTAS.nNotaFinal); 
           END IF;
        END LOOP;  
    END; 
    
    -- Aprobado_Curso que pasando como parámetro el código de curso nos indica si el
    -- alumno tiene aprobadas todas las asignaturas de ese curso
    
    MEMBER PROCEDURE Aprobado_Curso (codigo NUMBER) IS
    NOTA notas_t;
    SUSPENSO NUMBER;
    BEGIN
        SUSPENSO := 0;
        FOR i IN 1..SELF.NOTAS.COUNT LOOP
            NOTA := SELF.NOTAS(i);
            IF (NOTA.nCurso = xCurso) THEN
                IF (NOTA.nNotaFinal < 5) THEN
                    SUSPENSO := 1;
                END IF;
            END IF;
        END LOOP;
        IF (SUSPENSO = 1) THEN
            DBMS_OUTPUT.PUT_LINE(SELF.dNomAlu || ' ha suspendido el curso.');
        ELSE DBMS_OUTPUT.PUT_LINE(SELF.dNomAlu || ' ha aprobado el curso.');
        END IF;
    END;   
    
    -- Aprobar_Eval, si un alumno tiene aprobada la Evaluación Final actualizar las notas de
    -- la primera y segunda evaluación para que al menos tengan un 5.
    
    MEMBER PROCEDURE Aprobar_Eval IS
    BEGIN
        FOR i IN 1..NOTAS.COUNT LOOP
            IF (NOTAS(i).nNotaFinal >= 5) THEN
                IF (NOTAS(i).nNota1Ev < 5) THEN
                    DBMS_OUTPUT.PUT_LINE('Nota de la primera evaluación cambiada a 5');
                    NOTAS(i).self.nNota1Ev := 5;
                END IF;
                IF (NOTAS(i).nNota2Ev < 5) THEN
                    DBMS_OUTPUT.PUT_LINE('Nota de la segunda evaluación cambiada a 5');
                    NOTAS(i).self.nNota2Ev := 5;
                END IF;
            END IF;
        END LOOP;
    END;
    
    -- Alta_Notas método para dar de alta un nuevo registro de notas
    
    MEMBER PROCEDURE Alta_Notas (nota notas_t) IS
    BEGIN
        IF (SELF.NOTAS.COUNT < SELF.NOTAS.LIMIT) THEN
            SELF.NOTAS.EXTEND();
            SELF.NOTAS(NOTAS.COUNT) := nota;
        END IF;
    END;
    
    -- PROCEDIMIENTO QUE DEVUELVA ASIGNATURAS APROBADAS Y SUSPENSAS EN UN CURSO
    
    
    
END;



