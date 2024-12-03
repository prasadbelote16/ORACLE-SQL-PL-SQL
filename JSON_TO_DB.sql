CREATE TABLE employees_json (
    emp_id NUMBER,
    emp_name VARCHAR2(100),
    salary NUMBER,
    json_data CLOB
);


SET SERVEROUTPUT ON;
DECLARE
    -- Declare a BFILE for the source file (your JSON file)
    l_src_loc BFILE := BFILENAME('DATA_PUMP', 'employee_data.json');  -- Directory object and file name
    
    -- Declare a CLOB to store the file content
    l_dst_loc CLOB;
    
    -- Declare other necessary variables
    l_amt NUMBER := DBMS_LOB.lobmaxsize;  -- Max size of the BLOB
    l_dst_offset NUMBER := 1;  -- Starting point in the CLOB (start from the beginning)
    l_src_offset NUMBER := 1;  -- Starting point in the BFILE (start from the beginning)
    l_cs_id NUMBER := DBMS_LOB.default_csid;  -- Default character set
    l_lang_ctx NUMBER := DBMS_LOB.default_lang_ctx;  -- Default language context
    l_warning NUMBER;  -- For warning info
BEGIN
    -- Create temporary CLOB
    DBMS_LOB.createtemporary(l_dst_loc, TRUE);
    
    -- Open the source BFILE for reading
    DBMS_LOB.fileopen(l_src_loc, DBMS_LOB.file_readonly);
    
    -- Load data from the BFILE into the CLOB
    DBMS_LOB.loadclobfromfile(
        l_dst_loc,         -- Destination CLOB
        l_src_loc,         -- Source BFILE
        l_amt,             -- Amount of data to load
        l_dst_offset,      -- Starting point in the CLOB
        l_src_offset,      -- Starting point in the BFILE
        l_cs_id,           -- Character set ID
        l_lang_ctx,        -- Language context
        l_warning          -- Warning variable
    );
    
    -- Close the source BFILE
    DBMS_LOB.fileclose(l_src_loc);
    
    -- Insert the JSON data into the table (example table with a CLOB column)
    INSERT INTO employees_json (emp_id, emp_name, salary, json_data)
    VALUES (
        JSON_VALUE(l_dst_loc, '$.emp_id'),
        JSON_VALUE(l_dst_loc, '$.emp_name'),
        JSON_VALUE(l_dst_loc, '$.salary'),
        l_dst_loc  -- Store the whole JSON data as a CLOB
    );

    -- Commit the transaction
    COMMIT;

    -- Output a success message
    DBMS_OUTPUT.PUT_LINE('JSON data successfully loaded and inserted into the database.');
EXCEPTION
    WHEN OTHERS THEN
        -- Handle errors
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/
