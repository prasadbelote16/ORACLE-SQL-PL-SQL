CREATE TABLE employee_data (
    emp_id   NUMBER,
    emp_name VARCHAR2(100),
    salary   NUMBER
);

SELECT * FROM employee_data;

SELECT * FROM ALL_DIRECTORIES;
SET SERVEROUTPUT ON;
DECLARE
   file_handle  UTL_FILE.file_type;
   line         VARCHAR2(4000);
   emp_id       NUMBER;
   emp_name     VARCHAR2(100);
   salary       NUMBER;
BEGIN
   -- Open the file for reading
   file_handle := UTL_FILE.fopen(location => 'DATA_PUMP', filename => 'employees.txt', open_mode => 'R');
   
   -- Read each line of the file
   LOOP
      BEGIN
         -- Read a line from the file
         UTL_FILE.get_line(file_handle, line);
         
         -- Parse the line into variables
         emp_id := TO_NUMBER(REGEXP_SUBSTR(line, '^[^,]+'));
         emp_name := REGEXP_SUBSTR(line, ',[^,]+', 1, 1);
         salary := TO_NUMBER(REGEXP_SUBSTR(line, '[^,]+$', 1, 1));
         
         -- Remove leading/trailing spaces or extra commas
         emp_name := TRIM(BOTH ',' FROM emp_name);
         
         -- Insert into the table
         INSERT INTO employee_data (emp_id, emp_name, salary)
         VALUES (emp_id, emp_name, salary);
         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            EXIT; -- Exit the loop when the file ends
         WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Error in parsing line: ' || line);
      END;
   END LOOP;
   
   -- Close the file
   UTL_FILE.fclose(file_handle);
   DBMS_OUTPUT.PUT_LINE('File processed successfully!');
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      -- Ensure the file is closed in case of an error
      IF UTL_FILE.is_open(file_handle) THEN
         UTL_FILE.fclose(file_handle);
      END IF;
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
