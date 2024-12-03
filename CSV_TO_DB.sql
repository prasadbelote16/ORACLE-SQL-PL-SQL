SET SERVEROUTPUT ON;
DECLARE
   file_handle  UTL_FILE.file_type;
   line         VARCHAR2(4000);
   eid       NUMBER;
   ename     VARCHAR2(100);
   esalary       NUMBER;
   is_header    BOOLEAN := TRUE; -- Flag to skip the header row
BEGIN
   -- Open the CSV file for reading
   file_handle := UTL_FILE.fopen(location => 'DATA_PUMP', filename => 'emp.csv', open_mode => 'R');
   
   -- Loop through each line in the file
   LOOP
      BEGIN
         -- Read a line from the file
         UTL_FILE.get_line(file_handle, line);
         
         -- Skip the first row (header)
         IF is_header THEN
            is_header := FALSE; -- Toggle the flag after skipping the header
            CONTINUE;
         END IF;
         
         -- Parse the CSV line into variables using REGEXP_SUBSTR
         eid := TO_NUMBER(REGEXP_SUBSTR(line, '[^,]+', 1, 1));
         ename := REGEXP_SUBSTR(line, '[^,]+', 1, 2);
         esalary := TO_NUMBER(REGEXP_SUBSTR(line, '[^,]+', 1, 3));
         
         -- Insert parsed data into the table
         INSERT INTO employee_data (emp_id, emp_name, salary)
         VALUES (eid, ename, esalary);
         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            -- Exit the loop if no more data
            EXIT;
         WHEN VALUE_ERROR THEN
            -- Handle parsing or conversion errors
            DBMS_OUTPUT.PUT_LINE('Error in parsing line: ' || line);
      END;
   END LOOP;

   -- Close the file
   UTL_FILE.fclose(file_handle);
   DBMS_OUTPUT.PUT_LINE('CSV file data inserted successfully');
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
