-- Slowly Changing Dimensions (SCD) are a common data warehousing concept used to manage and track changes in dimension data over time. There are several types of SCDs, each with its own approach to handling changes in dimension data. Here are the main types of SCDs:
-- 1. Type 0: No Changes Allowed
    -- In this type, once a record is inserted into the dimension table, it cannot be updated. Any changes to the dimension data are ignored, and the original record remains unchanged. This type is suitable for dimensions that are not expected to change, such as product categories or geographic locations.

    -- So, when the source has any change for a particular record, the existing record in the dimension table will not be updated.

    -- Example: A customer's date of birth never changes.

    -- Table:
    CREATE TABLE dim_customer_type0 (
        customer_id     INT PRIMARY KEY,
        name            VARCHAR(100),
        date_of_birth   DATE
    );

    -- Write (initial load only):
    INSERT INTO dim_customer_type0 (customer_id, name, date_of_birth)
    VALUES (1, 'Alice', '1990-05-15');

    -- Any subsequent changes are simply ignored — no UPDATE statements are run.

    -- Read:
    SELECT * FROM dim_customer_type0 WHERE customer_id = 1;


-- 2. Type 1: Overwrite
    -- In this type, when a change occurs in the dimension data, the existing record is updated with the new information. This means that historical data is lost, and only the most current information is retained. This type is suitable for dimensions where historical accuracy is not important, such as customer contact information.

    -- So, when the source has any change for a particular record, the existing record in the dimension table will be updated with the new information, and the old information will be lost.

    -- Example: A customer moves to a new city. We only care about the current city.

    -- Table:
    CREATE TABLE dim_customer_type1 (
        customer_id     INT PRIMARY KEY,
        name            VARCHAR(100),
        city            VARCHAR(100)
    );

    -- Write (initial load):
    INSERT INTO dim_customer_type1 (customer_id, name, city)
    VALUES (1, 'Alice', 'New York');

    -- Write (customer moves — overwrite the old value):
    UPDATE dim_customer_type1
    SET city = 'San Francisco'
    WHERE customer_id = 1;
    -- 'New York' is now lost forever.

    -- Read:
    SELECT * FROM dim_customer_type1 WHERE customer_id = 1;
    -- Returns: (1, 'Alice', 'San Francisco')


-- 3. Type 2: Add New Row
    -- In this type, when a change occurs in the dimension data, a new record is inserted into the dimension table with the updated information. The existing record is not modified, allowing for historical tracking of changes. This type is suitable for dimensions where historical accuracy is important, such as customer demographics or employee information.

    -- So, when the source has any change for a particular record, a new record will be inserted into the dimension table with the updated information, and the existing record will not be modified, allowing for historical tracking of changes.

    -- We maintain two additional columns in the dimension table: "Effective Date" and "Expiration Date". The "Effective Date" column indicates the date when the record became effective, while the "Expiration Date" column indicates the date when the record expired. When a new record is inserted for a change, the existing record's "Expiration Date" is updated to reflect the end of its validity, and the new record's "Effective Date" is set to the current date with expiration date set to null.

    -- This type will cause the table to store multiple records for the same entity, with each record representing a different version of the entity over time. This allows for historical analysis and tracking of changes, but it can also lead to increased storage requirements and more complexity/cost in querying the data.

    -- Example: A customer moves from New York to San Francisco. We want to keep the history.

    -- Table:
    CREATE TABLE dim_customer_type2 (
        surrogate_key   INT PRIMARY KEY AUTOINCREMENT,  -- new PK, since customer_id is no longer unique
        customer_id     INT,                            -- natural/business key
        name            VARCHAR(100),
        city            VARCHAR(100),
        effective_date  DATE,
        expiration_date DATE,
        is_current      BOOLEAN
    );

    -- Write (initial load):
    INSERT INTO dim_customer_type2 (customer_id, name, city, effective_date, expiration_date, is_current)
    VALUES (1, 'Alice', 'New York', '2024-01-01', NULL, TRUE);

    -- Write (customer moves — expire old row, insert new row):
    UPDATE dim_customer_type2
    SET expiration_date = '2025-06-15', is_current = FALSE
    WHERE customer_id = 1 AND is_current = TRUE;

    INSERT INTO dim_customer_type2 (customer_id, name, city, effective_date, expiration_date, is_current)
    VALUES (1, 'Alice', 'San Francisco', '2025-06-15', NULL, TRUE);

    -- Read (current state):
    SELECT * FROM dim_customer_type2
    WHERE customer_id = 1 AND is_current = TRUE;
    -- Returns: (_, 1, 'Alice', 'San Francisco', '2025-06-15', NULL, TRUE)

    -- Read (full history):
    SELECT * FROM dim_customer_type2
    WHERE customer_id = 1
    ORDER BY effective_date;
    -- Returns both rows: New York (expired) and San Francisco (current)

    -- Read (point-in-time — where did Alice live on 2024-07-01?):
    SELECT * FROM dim_customer_type2
    WHERE customer_id = 1
      AND effective_date <= '2024-07-01'
      AND (expiration_date > '2024-07-01' OR expiration_date IS NULL);
    -- Returns: New York


-- 4. Type 3: Add New Column
    -- In this type, when a change occurs in the dimension data, a new column is added to the dimension table to store the new information. The existing record is updated with the new information, and the old information is retained in the original column. This type is suitable for dimensions where only a limited number of changes are expected, such as product prices or customer preferences.
    
    -- So, when the source has any change for a particular record, a new column will be added to the dimension table to store the new information, and the existing record will be updated with the new information, while the old information will be retained in the original column. Better than this is to maintain two columns for each attribute: one for the current value and another for the previous value. This way, you can track changes without losing historical data, while still keeping the dimension table relatively simple.

    -- This means that we are not maintaining all the history but some history. This type allows for tracking changes while keeping the dimension table relatively simple, but it can lead to a proliferation (rapid increase) of columns if there are many attributes that may change over time.

    -- This allows the table to keep the number of rows constant, as only one record per entity is stored, and so the processing and storage requirements are lower compared to Type 2. However, it also means that only a limited history of changes is maintained, and it may not be suitable for dimensions where historical accuracy is important.

    -- Example: A customer moves. We keep only the current and previous city.

    -- Table:
    CREATE TABLE dim_customer_type3 (
        customer_id     INT PRIMARY KEY,
        name            VARCHAR(100),
        current_city    VARCHAR(100),
        previous_city   VARCHAR(100)
    );

    -- Write (initial load):
    INSERT INTO dim_customer_type3 (customer_id, name, current_city, previous_city)
    VALUES (1, 'Alice', 'New York', NULL);

    -- Write (customer moves — shift current to previous, set new current):
    UPDATE dim_customer_type3
    SET previous_city = current_city,
        current_city  = 'San Francisco'
    WHERE customer_id = 1;

    -- Read:
    SELECT * FROM dim_customer_type3 WHERE customer_id = 1;
    -- Returns: (1, 'Alice', 'San Francisco', 'New York')
    -- Note: if Alice moves again to Chicago, 'New York' is lost — only one level of history is preserved.


-- 5. Type 4: Add History Table
    -- In this type, when a change occurs in the dimension data, the existing record is updated with the new information, and a new record is inserted into a separate history table to track the changes. This allows for historical tracking of changes while keeping the main dimension table clean and efficient. This type is suitable for dimensions where historical accuracy is important, and there may be a large number of changes, such as customer transactions or employee performance.

    -- Example: Main table always has the latest state (like Type 1), but a history table tracks all changes (like Type 2).

    -- Tables:
    CREATE TABLE dim_customer_type4 (
        customer_id     INT PRIMARY KEY,
        name            VARCHAR(100),
        city            VARCHAR(100)
    );

    CREATE TABLE dim_customer_type4_history (
        history_id      INT PRIMARY KEY AUTOINCREMENT,
        customer_id     INT,
        name            VARCHAR(100),
        city            VARCHAR(100),
        effective_date  DATE,
        expiration_date DATE
    );

    -- Write (initial load):
    INSERT INTO dim_customer_type4 (customer_id, name, city)
    VALUES (1, 'Alice', 'New York');

    INSERT INTO dim_customer_type4_history (customer_id, name, city, effective_date, expiration_date)
    VALUES (1, 'Alice', 'New York', '2024-01-01', NULL);

    -- Write (customer moves — update main table, expire + insert in history):
    UPDATE dim_customer_type4
    SET city = 'San Francisco'
    WHERE customer_id = 1;

    UPDATE dim_customer_type4_history
    SET expiration_date = '2025-06-15'
    WHERE customer_id = 1 AND expiration_date IS NULL;

    INSERT INTO dim_customer_type4_history (customer_id, name, city, effective_date, expiration_date)
    VALUES (1, 'Alice', 'San Francisco', '2025-06-15', NULL);

    -- Read (current state — fast, simple query on main table):
    SELECT * FROM dim_customer_type4 WHERE customer_id = 1;

    -- Read (full history):
    SELECT * FROM dim_customer_type4_history
    WHERE customer_id = 1
    ORDER BY effective_date;


-- 6. Type 6: Hybrid
    -- In this type, a combination of the above types is used to manage changes in dimension data. For example, a Type 2 approach may be used for certain attributes, while a Type 1 approach may be used for others. This type is suitable for dimensions where different attributes have different requirements for historical tracking and accuracy.

    -- It is called Type 6 because it combines Types 1 + 2 + 3 (1+2+3=6).

    -- Example: We keep full history (Type 2 rows), a previous value column (Type 3), and overwrite the current value on all rows (Type 1).

    -- Table:
    CREATE TABLE dim_customer_type6 (
        surrogate_key   INT PRIMARY KEY AUTOINCREMENT,
        customer_id     INT,
        name            VARCHAR(100),
        current_city    VARCHAR(100),   -- Type 1: always the latest value across ALL rows
        previous_city   VARCHAR(100),   -- Type 3: the value before the current one
        historical_city VARCHAR(100),   -- Type 2: the city that was valid during this row's time range
        effective_date  DATE,
        expiration_date DATE,
        is_current      BOOLEAN
    );

    -- Write (initial load):
    INSERT INTO dim_customer_type6
        (customer_id, name, current_city, previous_city, historical_city, effective_date, expiration_date, is_current)
    VALUES
        (1, 'Alice', 'New York', NULL, 'New York', '2024-01-01', NULL, TRUE);

    -- Write (customer moves to San Francisco):
    -- Step 1: Expire the old row
    UPDATE dim_customer_type6
    SET expiration_date = '2025-06-15', is_current = FALSE
    WHERE customer_id = 1 AND is_current = TRUE;

    -- Step 2: Insert new current row
    INSERT INTO dim_customer_type6
        (customer_id, name, current_city, previous_city, historical_city, effective_date, expiration_date, is_current)
    VALUES
        (1, 'Alice', 'San Francisco', 'New York', 'San Francisco', '2025-06-15', NULL, TRUE);

    -- Step 3 (Type 1 part): Update current_city on ALL rows for this customer
    UPDATE dim_customer_type6
    SET current_city = 'San Francisco'
    WHERE customer_id = 1;

    -- Read (current state):
    SELECT * FROM dim_customer_type6
    WHERE customer_id = 1 AND is_current = TRUE;

    -- Read (full history with context):
    SELECT customer_id, historical_city, current_city, previous_city, effective_date, expiration_date
    FROM dim_customer_type6
    WHERE customer_id = 1
    ORDER BY effective_date;
    -- Every row shows: what city applied then (historical_city), what's current now (current_city), and what came before (previous_city).

    -- Example state after: New York → San Francisco → Chicago:
    -- SK | CUR_CITY | PREV_CITY     | HIST_CITY     | EFF_DATE   | EXP_DATE
    -- 1  | Chicago  | San Francisco | New York      | 2024-01-01 | 2025-06-15
    -- 2  | Chicago  | San Francisco | San Francisco | 2025-06-15 | 2026-03-01
    -- 3  | Chicago  | San Francisco | Chicago       | 2026-03-01 | NULL


-- Each type of SCD has its own advantages and disadvantages, and the choice of which type to use depends on the specific requirements of the data warehouse and the nature of the dimension data being managed. It is important to carefully consider the trade-offs between historical accuracy, data integrity, and performance when selecting the appropriate SCD type for a given dimension.