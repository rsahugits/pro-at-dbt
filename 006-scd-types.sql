-- Slowly Changing Dimensions (SCD) are a common data warehousing concept used to manage and track changes in dimension data over time. There are several types of SCDs, each with its own approach to handling changes in dimension data. Here are the main types of SCDs:
-- 1. Type 0: No Changes Allowed
    -- In this type, once a record is inserted into the dimension table, it cannot be updated. Any changes to the dimension data are ignored, and the original record remains unchanged. This type is suitable for dimensions that are not expected to change, such as product categories or geographic locations.

    -- So, when the source has any change for a particular record, the existing record in the dimension table will not be updated.


-- 2. Type 1: Overwrite
    -- In this type, when a change occurs in the dimension data, the existing record is updated with the new information. This means that historical data is lost, and only the most current information is retained. This type is suitable for dimensions where historical accuracy is not important, such as customer contact information.

    -- So, when the source has any change for a particular record, the existing record in the dimension table will be updated with the new information, and the old information will be lost.

-- 3. Type 2: Add New Row
    -- In this type, when a change occurs in the dimension data, a new record is inserted into the dimension table with the updated information. The existing record is not modified, allowing for historical tracking of changes. This type is suitable for dimensions where historical accuracy is important, such as customer demographics or employee information.

    -- So, when the source has any change for a particular record, a new record will be inserted into the dimension table with the updated information, and the existing record will not be modified, allowing for historical tracking of changes.

    -- We maintain two additional columns in the dimension table: "Effective Date" and "Expiration Date". The "Effective Date" column indicates the date when the record became effective, while the "Expiration Date" column indicates the date when the record expired. When a new record is inserted for a change, the existing record's "Expiration Date" is updated to reflect the end of its validity, and the new record's "Effective Date" is set to the current date with expiration date set to null.

    -- This type will cause the table to store multiple records for the same entity, with each record representing a different version of the entity over time. This allows for historical analysis and tracking of changes, but it can also lead to increased storage requirements and more complexity/cost in querying the data.

-- 4. Type 3: Add New Column
    -- In this type, when a change occurs in the dimension data, a new column is added to the dimension table to store the new information. The existing record is updated with the new information, and the old information is retained in the original column. This type is suitable for dimensions where only a limited number of changes are expected, such as product prices or customer preferences.
    
    -- So, when the source has any change for a particular record, a new column will be added to the dimension table to store the new information, and the existing record will be updated with the new information, while the old information will be retained in the original column. Better than this is to maintain two columns for each attribute: one for the current value and another for the previous value. This way, you can track changes without losing historical data, while still keeping the dimension table relatively simple.

    -- This means that we are not maintaining all the history but some history. This type allows for tracking changes while keeping the dimension table relatively simple, but it can lead to a proliferation (rapid increase) of columns if there are many attributes that may change over time.

    -- This allows the table to keep the number of rows constant, as only one record per entity is stored, and so the processing and storage requirements are lower compared to Type 2. However, it also means that only a limited history of changes is maintained, and it may not be suitable for dimensions where historical accuracy is important.


-- 5. Type 4: Add History Table
    -- In this type, when a change occurs in the dimension data, the existing record is updated with the new information, and a new record is inserted into a separate history table to track the changes. This allows for historical tracking of changes while keeping the main dimension table clean and efficient. This type is suitable for dimensions where historical accuracy is important, and there may be a large number of changes, such as customer transactions or employee performance.


-- 6. Type 6: Hybrid
    -- In this type, a combination of the above types is used to manage changes in dimension data. For example, a Type 2 approach may be used for certain attributes, while a Type 1 approach may be used for others. This type is suitable for dimensions where different attributes have different requirements for historical tracking and accuracy.

-- Each type of SCD has its own advantages and disadvantages, and the choice of which type to use depends on the specific requirements of the data warehouse and the nature of the dimension data being managed. It is important to carefully consider the trade-offs between historical accuracy, data integrity, and performance when selecting the appropriate SCD type for a given dimension.