
DROP TABLE IF EXISTS "sales";
DROP TABLE IF EXISTS "products";
DROP TABLE IF EXISTS "customers";


CREATE TABLE "customers" (
    "CustomerID" SERIAL PRIMARY KEY,
    "FirstName" VARCHAR(50) NOT NULL,
    "LastName" VARCHAR(50),
    "Email" VARCHAR(255) UNIQUE NOT NULL,
    "PhoneNumber" VARCHAR(15)
);


CREATE TABLE "products" (
    "ProductID" SERIAL PRIMARY KEY,
    "ProductName" VARCHAR(50) NOT NULL,
    "Price" NUMERIC,
    "StockQuantity" INT
);


CREATE TABLE "sales" (
    "SaleID" SERIAL PRIMARY KEY,
    "CustomerID" INT,
    "ProductID" INT,
    "SaleDate" TIMESTAMP, 
    "TotalPrice" NUMERIC,
    "QuantitySold" INT,
    CONSTRAINT fk_customer FOREIGN KEY ("CustomerID") REFERENCES "customers"("CustomerID"),
    CONSTRAINT fk_product FOREIGN KEY ("ProductID") REFERENCES "products"("ProductID")
);


\copy customers ("FirstName", "LastName", "Email", "PhoneNumber") FROM 'C:/Users/kabir lamin/Documents/smatdata-tasks/sql/customers.csv' WITH CSV HEADER DELIMITER ',';
\copy products ("ProductName", "Price", "StockQuantity") FROM 'C:/Users/kabir lamin/Documents/smatdata-tasks/sql/products.csv' WITH CSV HEADER DELIMITER ',';
\copy sales ("CustomerID", "ProductID", "SaleDate", "TotalPrice", "QuantitySold") FROM 'C:/Users/kabir lamin/Documents/smatdata-tasks/sql/sales.csv' WITH CSV HEADER DELIMITER ',';

CREATE OR REPLACE PROCEDURE UpdateStock(
    p_ProductID INT,
    p_QuantitySold INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET StockQuantity = StockQuantity - p_QuantitySold
    WHERE ProductID = p_ProductID;

    IF (SELECT StockQuantity FROM products WHERE ProductID = p_ProductID) < 0 THEN
        RAISE EXCEPTION 'Stock quantity cannot be negative for ProductID: %', p_ProductID;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE AddSale(
    p_CustomerID INT,
    p_ProductID INT,
    p_SaleDate TIMESTAMP,
    p_TotalPrice NUMERIC,
    p_QuantitySold INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO sales (CustomerID, ProductID, SaleDate, TotalPrice, QuantitySold)
    VALUES (p_CustomerID, p_ProductID, p_SaleDate, p_TotalPrice, p_QuantitySold);

    CALL UpdateStock(p_ProductID, p_QuantitySold);
END;
$$;


CREATE OR REPLACE FUNCTION CheckStock()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT StockQuantity FROM products WHERE ProductID = NEW.ProductID) < NEW.QuantitySold THEN
        RAISE EXCEPTION 'Insufficient stock for ProductID: %', NEW.ProductID;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER CheckStock
BEFORE INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION CheckStock();


CREATE OR REPLACE FUNCTION NotifyLowStock()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT StockQuantity FROM products WHERE ProductID = NEW.ProductID) < 5 THEN
        RAISE NOTICE 'Warning: Stock for ProductID % is below 5 units.', NEW.ProductID;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER NotifyLowStock
AFTER INSERT ON sales
FOR EACH ROW
EXECUTE FUNCTION NotifyLowStock();
