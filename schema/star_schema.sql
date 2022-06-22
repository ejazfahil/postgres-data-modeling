-- Star schema 2022-06-22
CREATE TABLE dim_customer (
  customer_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  segment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE dim_product (
  product_id SERIAL PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  category TEXT,
  unit_price NUMERIC(10,2)
);

CREATE TABLE fact_sales (
  sale_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES dim_customer,
  product_id INT REFERENCES dim_product,
  quantity INT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  sold_at TIMESTAMPTZ NOT NULL
);
