INSERT INTO DimDate (date_pk, date_actual, year, month, day, quarter, day_of_week, week_of_year, is_weekend)
SELECT
    TO_CHAR(d::date, 'YYYYMMDD')::integer AS date_pk,
    d::date AS date_actual,
    EXTRACT(YEAR FROM d::date) AS year,
    EXTRACT(MONTH FROM d::date) AS month,
    EXTRACT(DAY FROM d::date) AS day,
    EXTRACT(QUARTER FROM d::date) AS quarter,
    EXTRACT(ISODOW FROM d::date) AS day_of_week,
    EXTRACT(WEEK FROM d::date) AS week_of_year,
    EXTRACT(ISODOW FROM d::date) IN (6, 7) AS is_weekend
FROM (
    SELECT DISTINCT sale_date AS raw_date FROM mock_data_raw WHERE NULLIF(TRIM(sale_date), '') IS NOT NULL
    UNION
    SELECT DISTINCT product_release_date AS raw_date FROM mock_data_raw WHERE NULLIF(TRIM(product_release_date), '') IS NOT NULL
    UNION
    SELECT DISTINCT product_expiry_date AS raw_date FROM mock_data_raw WHERE NULLIF(TRIM(product_expiry_date), '') IS NOT NULL
) AS dates_source
CROSS JOIN LATERAL (SELECT TO_DATE(dates_source.raw_date, 'MM/DD/YYYY')) AS s(d)
WHERE s.d IS NOT NULL
ON CONFLICT (date_actual) DO NOTHING;


INSERT INTO DimCustomers (customer_id_source, first_name, last_name, age, email, country, postal_code, pet_type, pet_name, pet_breed)
SELECT DISTINCT
    NULLIF(TRIM(sale_customer_id), '')::INTEGER,
    NULLIF(TRIM(customer_first_name), ''),
    NULLIF(TRIM(customer_last_name), ''),
    NULLIF(TRIM(customer_age), '')::INTEGER,
    TRIM(customer_email),
    NULLIF(TRIM(customer_country), ''),
    NULLIF(TRIM(customer_postal_code), ''),
    NULLIF(TRIM(customer_pet_type), ''),
    NULLIF(TRIM(customer_pet_name), ''),
    NULLIF(TRIM(customer_pet_breed), '')
FROM mock_data_raw
WHERE NULLIF(TRIM(customer_email), '') IS NOT NULL
ON CONFLICT (email) DO NOTHING;


INSERT INTO DimSellers (seller_id_source, first_name, last_name, email, country, postal_code)
SELECT DISTINCT
    NULLIF(TRIM(sale_seller_id), '')::INTEGER,
    NULLIF(TRIM(seller_first_name), ''),
    NULLIF(TRIM(seller_last_name), ''),
    TRIM(seller_email),
    NULLIF(TRIM(seller_country), ''),
    NULLIF(TRIM(seller_postal_code), '')
FROM mock_data_raw
WHERE NULLIF(TRIM(seller_email), '') IS NOT NULL
ON CONFLICT (email) DO NOTHING;


INSERT INTO DimSuppliers (name, contact_person, email, phone, address, city, country)
SELECT DISTINCT
    TRIM(supplier_name),
    NULLIF(TRIM(supplier_contact), ''),
    NULLIF(TRIM(supplier_email), ''),
    NULLIF(TRIM(supplier_phone), ''),
    NULLIF(TRIM(supplier_address), ''),
    NULLIF(TRIM(supplier_city), ''),
    NULLIF(TRIM(supplier_country), '')
FROM mock_data_raw
WHERE NULLIF(TRIM(supplier_name), '') IS NOT NULL
ON CONFLICT (name) DO NOTHING;


INSERT INTO DimStores (name, location_details, city, state_code, country, phone, email)
SELECT DISTINCT
    TRIM(store_name),
    NULLIF(TRIM(store_location), ''),
    NULLIF(TRIM(store_city), ''),
    NULLIF(TRIM(store_state), ''),
    NULLIF(TRIM(store_country), ''),
    NULLIF(TRIM(store_phone), ''),
    TRIM(store_email)
FROM mock_data_raw
WHERE NULLIF(TRIM(store_name), '') IS NOT NULL AND NULLIF(TRIM(store_email), '') IS NOT NULL
ON CONFLICT (name, city, country, email) DO NOTHING;


INSERT INTO DimProductCategories (category_name)
SELECT DISTINCT
    TRIM(product_category)
FROM mock_data_raw
WHERE NULLIF(TRIM(product_category), '') IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;


INSERT INTO DimProductBrands (brand_name)
SELECT DISTINCT
    TRIM(product_brand)
FROM mock_data_raw
WHERE NULLIF(TRIM(product_brand), '') IS NOT NULL
ON CONFLICT (brand_name) DO NOTHING;


INSERT INTO DimProductPetCategories (pet_category_name)
SELECT DISTINCT
    TRIM(pet_category)
FROM mock_data_raw
WHERE NULLIF(TRIM(pet_category), '') IS NOT NULL
ON CONFLICT (pet_category_name) DO NOTHING;


INSERT INTO DimProducts (
    product_id_source, name, category_fk, price, inventory_quantity,
    weight_grams, color, size_description, brand_fk, material,
    description, rating, reviews_count, release_date, expiry_date,
    supplier_fk, pet_category_fk
)
SELECT DISTINCT
    md.sale_product_id::INTEGER,
    TRIM(md.product_name),
    cat.category_pk,
    NULLIF(TRIM(md.product_price), '')::DECIMAL(10,2),
    NULLIF(TRIM(md.product_quantity), '')::INTEGER,
    NULLIF(TRIM(md.product_weight), '')::DECIMAL(10,2),
    NULLIF(TRIM(md.product_color), ''),
    NULLIF(TRIM(md.product_size), ''),
    brand.brand_pk,
    NULLIF(TRIM(md.product_material), ''),
    NULLIF(TRIM(md.product_description), ''),
    NULLIF(TRIM(md.product_rating), '')::DECIMAL(3,1),
    NULLIF(TRIM(md.product_reviews), '')::INTEGER,
    CASE WHEN NULLIF(TRIM(md.product_release_date), '') IS NOT NULL THEN TO_DATE(md.product_release_date, 'MM/DD/YYYY') ELSE NULL END,
    CASE WHEN NULLIF(TRIM(md.product_expiry_date), '') IS NOT NULL THEN TO_DATE(md.product_expiry_date, 'MM/DD/YYYY') ELSE NULL END,
    sup.supplier_pk,
    pet_cat.pet_category_pk
FROM mock_data_raw md
LEFT JOIN DimProductCategories cat ON TRIM(md.product_category) = cat.category_name
LEFT JOIN DimProductBrands brand ON TRIM(md.product_brand) = brand.brand_name
LEFT JOIN DimSuppliers sup ON TRIM(md.supplier_name) = sup.name
LEFT JOIN DimProductPetCategories pet_cat ON TRIM(md.pet_category) = pet_cat.pet_category_name
WHERE NULLIF(TRIM(md.product_name), '') IS NOT NULL AND NULLIF(TRIM(md.product_brand), '') IS NOT NULL
ON CONFLICT (name, brand_fk) DO NOTHING;

INSERT INTO FactSales (
    date_fk,
    customer_fk,
    seller_fk,
    product_fk,
    store_fk,
    quantity_sold,
    total_price,
    source_id,
    source_file_row_id_fk
)
SELECT
    d.date_pk,
    dc.customer_pk,
    ds.seller_pk,
    dp.product_pk,
    dst.store_pk,
    NULLIF(TRIM(md.sale_quantity), '')::INTEGER,
    NULLIF(TRIM(md.sale_total_price), '')::DECIMAL(12,2),
    NULLIF(TRIM(md.id), '')::INTEGER,
    md.source_file_row_id
FROM mock_data_raw md
LEFT JOIN DimDate d ON d.date_actual = TO_DATE(md.sale_date, 'MM/DD/YYYY')
LEFT JOIN DimCustomers dc ON dc.email = TRIM(md.customer_email)
LEFT JOIN DimSellers ds ON ds.email = TRIM(md.seller_email)
LEFT JOIN DimStores dst ON dst.name = TRIM(md.store_name) AND dst.email = TRIM(md.store_email)
LEFT JOIN DimProductBrands brand ON brand.brand_name = TRIM(md.product_brand) 
LEFT JOIN DimProducts dp ON dp.name = TRIM(md.product_name) AND dp.brand_fk = brand.brand_pk
WHERE
    NULLIF(TRIM(md.sale_date), '') IS NOT NULL AND
    NULLIF(TRIM(md.customer_email), '') IS NOT NULL AND
    NULLIF(TRIM(md.seller_email), '') IS NOT NULL AND
    NULLIF(TRIM(md.store_name), '') IS NOT NULL AND NULLIF(TRIM(md.store_email), '') IS NOT NULL AND
    NULLIF(TRIM(md.product_name), '') IS NOT NULL AND NULLIF(TRIM(md.product_brand), '') IS NOT NULL;