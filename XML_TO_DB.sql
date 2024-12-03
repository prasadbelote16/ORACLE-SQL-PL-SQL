CREATE OR REPLACE DIRECTORY xml_dir AS 'D:\ServerFolder';
GRANT READ, WRITE ON DIRECTORY xml_dir TO your_user;


select  * from all_directories;

CREATE TABLE customer_data (
    customer_id NUMBER,
    customer_name VARCHAR2(100),
    customer_email VARCHAR2(100)
);


--- CHECK ACCESSIBILTY OF FILE 
DECLARE
    v_file BFILE;
BEGIN
    v_file := BFILENAME('XML_DIR', 'customers.xml');
    DBMS_LOB.OPEN(v_file, DBMS_LOB.LOB_READONLY);
    DBMS_LOB.CLOSE(v_file);
    DBMS_OUTPUT.PUT_LINE('File is accessible.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;



create or replace function read_clob_from_file(p_directory    varchar2
                               ,p_filename varchar2) return clob is

      l_amt        number := dbms_lob.lobmaxsize;
      l_dst_loc    clob;
      l_dst_offset number := 1;
      l_lang_ctx   number := dbms_lob.default_lang_ctx;
      l_src_loc    bfile;
      l_src_offset number := 1;
      l_warning    number;
   begin

      l_src_loc := bfilename(p_directory, p_filename);
      dbms_lob.createtemporary(l_dst_loc, true);
      dbms_lob.fileopen(l_src_loc, dbms_lob.file_readonly);
      dbms_lob.loadclobfromfile(l_dst_loc
                               ,l_src_loc
                               ,l_amt
                               ,l_dst_offset
                               ,l_src_offset
                               ,dbms_lob.default_csid
                               ,l_lang_ctx
                               ,l_warning);
      dbms_lob.fileclose(l_src_loc);
      return l_dst_loc;
   end;
   
SET SERVEROUTPUT ON; 
   DECLARE
    v_clob CLOB;
BEGIN
    -- Call the function with directory and file name
    v_clob := read_clob_from_file('DATA_PUMP', 'customers.xml');

    -- Print the first 1000 characters to confirm
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_clob, 1000, 1));

    -- Optional: Process the CLOB content as XML
    FOR rec IN (
        SELECT 
            EXTRACTVALUE(VALUE(x), '/customer/id') AS customer_id,
            EXTRACTVALUE(VALUE(x), '/customer/name') AS customer_name,
            EXTRACTVALUE(VALUE(x), '/customer/email') AS customer_email
        FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(v_clob), '/customers/customer'))) x
    )
    LOOP
        -- Insert parsed data into the table
        INSERT INTO customer_data (customer_id, customer_name, customer_email)
        VALUES (rec.customer_id, rec.customer_name, rec.customer_email);
    END LOOP;

    -- Commit changes
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('File processed and data inserted successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;


SELECT * FROM customer_data;