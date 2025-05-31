CREATE TABLE DimCustomers (
    customer_pk SERIAL PRIMARY KEY,
    customer_id_source INTEGER,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    age INTEGER,
    email VARCHAR(255) UNIQUE,
    country VARCHAR(100),
    postal_code VARCHAR(20),
    pet_type VARCHAR(50),
    pet_name VARCHAR(100),
    pet_breed VARCHAR(100)
);

CREATE TABLE DimSellers (
    seller_pk SERIAL PRIMARY KEY,
    seller_id_source INTEGER,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    country VARCHAR(100),
    postal_code VARCHAR(20)
);

CREATE TABLE DimSuppliers (
    supplier_pk SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE,
    contact_person VARCHAR(200),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE DimStores (
    store_pk SERIAL PRIMARY KEY,
    name VARCHAR(255),
    location_details VARCHAR(255),
    city VARCHAR(100),
    state_code VARCHAR(50),
    country VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    UNIQUE (name, city, country, email)
);

CREATE TABLE DimProductCategories (
    category_pk SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE
);

CREATE TABLE DimProductBrands (
    brand_pk SERIAL PRIMARY KEY,
    brand_name VARCHAR(100) UNIQUE
);

CREATE TABLE DimProductPetCategories (
    pet_category_pk SERIAL PRIMARY KEY,
    pet_category_name VARCHAR(100) UNIQUE
);

CREATE TABLE DimProducts (
    product_pk SERIAL PRIMARY KEY,
    product_id_source INTEGER,
    name VARCHAR(255),
    category_fk INTEGER REFERENCES DimProductCategories(category_pk),
    price DECIMAL(10, 2),
    inventory_quantity INTEGER,
    weight_grams DECIMAL(10, 2),
    color VARCHAR(50),
    size_description VARCHAR(50),
    brand_fk INTEGER REFERENCES DimProductBrands(brand_pk),
    material VARCHAR(100),
    description TEXT,
    rating DECIMAL(3, 1),
    reviews_count INTEGER,
    release_date DATE,
    expiry_date DATE,
    supplier_fk INTEGER REFERENCES DimSuppliers(supplier_pk),
    pet_category_fk INTEGER REFERENCES DimProductPetCategories(pet_category_pk),
    UNIQUE (name, brand_fk)
);

CREATE TABLE DimDate (
    date_pk INTEGER PRIMARY KEY,
    date_actual DATE UNIQUE NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    day INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    week_of_year INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE FactSales (
    sales_pk BIGSERIAL PRIMARY KEY,
    date_fk INTEGER NOT NULL REFERENCES DimDate(date_pk),
    customer_fk INTEGER NOT NULL REFERENCES DimCustomers(customer_pk),
    seller_fk INTEGER NOT NULL REFERENCES DimSellers(seller_pk),
    product_fk INTEGER NOT NULL REFERENCES DimProducts(product_pk),
    store_fk INTEGER NOT NULL REFERENCES DimStores(store_pk),
    quantity_sold INTEGER,
    total_price DECIMAL(12, 2),
    source_id INTEGER,
    source_file_row_id_fk INTEGER REFERENCES mock_data_raw(source_file_row_id)
);

CREATE INDEX idx_factsales_date_fk ON FactSales(date_fk);
CREATE INDEX idx_factsales_customer_fk ON FactSales(customer_fk);
CREATE INDEX idx_factsales_product_fk ON FactSales(product_fk);
CREATE INDEX idx_factsales_store_fk ON FactSales(store_fk);