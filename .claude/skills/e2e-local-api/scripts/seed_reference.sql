\set ON_ERROR_STOP on
INSERT INTO technicians (technician_name, number) VALUES ('Tecnico Sintetico', '11900000001');
INSERT INTO types (type) VALUES ('Celular');
INSERT INTO brands (brand) VALUES ('MarcaTeste');
INSERT INTO models (model) VALUES ('ModeloX');
INSERT INTO brands_models_types (id_brand, id_model, id_type) SELECT b.id, m.id, t.id FROM brands b, models m, types t;
INSERT INTO colors (color) VALUES ('Preto');
INSERT INTO customers (name, cpf, gender, email) VALUES ('Cliente Sintetico', '52998224725', 'MALE', 'sintetico@example.test');
INSERT INTO phones (number, alias) VALUES ('11988887777', 'Principal');
INSERT INTO customer_phones (id_customer, id_phone, is_main) SELECT c.id, p.id, true FROM customers c, phones p;
INSERT INTO devices (id_customer, id_brand_model_type, device_status, id_technician, entry_date, problem, observation, budget, service_value, color_ids, has_urgency, is_revision, last_update)
SELECT c.id, bmt.id, 'NOVO', t.id, now(), 'Nao liga', 'Obs inicial', 'Troca de tela', 300.00, ARRAY[(SELECT id FROM colors LIMIT 1)], false, false, now()
FROM customers c, brands_models_types bmt, technicians t;
