BEGIN;
DELETE FROM payments;
DELETE FROM order_items;
DELETE FROM orders;
DELETE FROM reservations;
UPDATE dining_tables SET status = 'FREE' WHERE status IN ('OCCUPIED', 'RESERVED');
ALTER SEQUENCE public."orders_orderNumber_seq" RESTART WITH 1;
COMMIT;
