-- TABLA DE ADMINISTRACIÓN Y PERSONAS
-- 1. Tipos de roles
create table if not exists roles (
  cod_role serial primary key,
  desc_role varchar(80) unique not null,
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);

-- 2. Usuarios del sistema
create table if not exists users (
  cod_user serial primary key,
  name varchar(120) not null,
  email varchar(150) unique not null,
  google_id varchar(255), -- para el login social
  password_hash varchar(255),
  cod_role int not null,
  is_active boolean default true, -- Para saber si el usuario esta activo
  last_login_at timestamp with time zone, -- último acceso al sistema
  created_at timestamp with time zone default current_timestamp,

  constraint fk_cod_role_users foreign key (cod_role) references roles(cod_role)
);

-- 3. Tipos de cliente
create table if not exists client_types (
  cod_client_type serial primary key,
  desc_client_type varchar(80) unique not null,
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);

-- 4. Clientes (personas o empresas)
create table if not exists clients (
  cod_client serial primary key,
  cod_client_type int not null,

  -- Datos comunes
  full_name varchar(150) not null,
  run varchar(12), -- run completo no obligatorio (el dv_run se autocalcula en el front)
  email varchar(150),
  phone varchar(20),
  address text,
  notes text, -- preferencias del cliente
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp,
  updated_at timestamp with time zone default current_timestamp,

  constraint fk_cod_client_type_clients foreign key (cod_client_type) references client_types(cod_client_type) on delete restrict
);

-- 5. Relaciones entre clientes y empresas
create table if not exists client_relationships (
  cod_relationship serial primary key,
  cod_client_company int not null,  -- La empresa
  cod_client_person int not null,   -- El trabajador relacionado a la empresa
  position varchar(100),            -- Cargo en la empresa: "trabajador", "secretaria", "gerente"
  is_active boolean default true,   -- Por si el cliente deja de pertenecer a la empresa, no borra historial, solo desactiva
  created_at timestamp with time zone default current_timestamp,

  -- CLAVE ÚNICA: Trabajador solo puede tener un cargo en esa empresa a la vez (opcional)
  unique(cod_client_company, cod_client_person),

  -- A. Si borro la emrpesa se borra el vínculo pero el cliente sigue existiendo en la tabla clientes
  constraint fk_cod_client_company_relationships foreign key (cod_client_company) references clients(cod_client) on delete cascade,
  -- B. Si borro el cliente, se borra el vínculo
  constraint fk_cod_client_person_relationships foreign key (cod_client_person) references clients(cod_client) on delete cascade
);

-- 6. Proveedores
create table if not exists suppliers (
  cod_supplier serial primary key,
  company_name varchar(150) unique not null,
  contact_name varchar(100),
  email varchar(150),
  phone varchar(20),
  website varchar(150),
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);


-- TABLA DE INVENTARIO Y ACTIVOS
-- 7. tipos de dispositivos
create table if not exists type_device (
  cod_type_device serial primary key,
  desc_type_device varchar(100) unique not null,
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);

-- 8. Equipos (dispositivos de los clientes)
create table if not exists devices (
  cod_device serial primary key,
  cod_client int not null, -- Dueño real del dispositivo
  cod_type_device int not null,
  desc_device varchar(80) not null,
  brand varchar(50),
  model varchar(100),
  serial_number varchar(100) unique,
  password_access boolean default false, -- Si dejó o proporcionó clave de acceso del dispositivo
  specifications text, -- RAM, Disco, Procesador (JSON o texto)
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp,

  constraint fk_cod_client_devices foreign key (cod_client) references clients(cod_client) on delete restrict,
  constraint fk_cod_type_device_devices foreign key (cod_type_device) references type_device(cod_type_device)
);

-- 9. Productos (Inventario físico)
create table if not exists products (
  cod_product  serial primary key,
  cod_supplier int not null,
  desc_product varchar(150) not null,
  description text,
  cost_price decimal(10, 2) not null, -- Precio de compra
  sale_price decimal(10, 2) not null, -- Precio de venta
  stock_current int default 0,
  stock_min int default 2, -- Para alertar el stock mínimo
  sku varchar(50) unique, -- Código de barras o interno
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp,

  constraint check_product_stock_non_negative check (stock_current >= 0),
  constraint check_products_price_valid check (sale_price >= cost_price),

  constraint fk_cod_supplier_products foreign key (cod_supplier) references suppliers(cod_supplier) on delete restrict
);

-- 10. Servicios (Mano de obra)
create table if not exists services (
  cod_service serial primary key,
  desc_service varchar(150) unique not null, -- Ej: "Formateo equipos Windows"
  description text,
  base_price decimal(10, 2) not null,
  estimated_hours decimal(4, 1), -- Duración estimada
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp,

  constraint check_services_base_price_positive check (base_price >= 0),
  constraint check_services_estimated_hours_positive check (estimated_hours is null or estimated_hours >= 0)
);


-- TABLAS DE DATOS AUXILIARES
-- 11. Categoría de documentos
create table if not exists document_categories (
  cod_document_category serial primary key,
  document_category_key varchar(50) unique not null,       -- 'quote', 'work_order'
  desc_document_category varchar(100) not null,            -- 'Cotización', 'Orden de trabajo'
  description text,
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);

-- 12. Estados de un documento
create table if not exists document_status (
  cod_document_status serial primary key,
  desc_document_status varchar(80) unique not null,
  cod_document_category int not null,       -- Categoría de cocumentos
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp,

  constraint fk_cod_document_category_document_status foreign key (cod_document_category) references document_categories(cod_document_category) on delete restrict
);

-- 13. Tipos producto / servicio
create table if not exists work_item_types (
  cod_work_item_type serial primary key,
  desc_work_item_type varchar(80) unique not null,
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);

-- 14. Tipos de transacciones
create table if not exists transaction_types (
  cod_transaction_type serial primary key,
  desc_transaction_type varchar(80) unique not null,
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);

-- 15. Tipos de entidades
create table if not exists entity_types (
  cod_entity_type serial primary key,
  entity_key varchar(50) unique not null,   -- 'client', 'device', 'work_order'
  desc_entity varchar(100) not null,        -- Nombre legible: 'Cliente', 'Equipo'
  description text,
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);


-- DOCUMENTOS Y REGISTROS
-- 16. Cotizaciones (Paso previo opcional)
create table if not exists quotes (
  cod_quote serial primary key,
  cod_client int not null,
  cod_device int not null,
  total_amount decimal(10, 2) default 0,
  cod_document_status int not null,       -- Estado del documento (borrador - Solo muestra categoría cotizaciones)
  valid_until date,                       -- Fecha de validés del documento
  created_at timestamp with time zone default current_timestamp,
  updated_at timestamp with time zone default current_timestamp,

  constraint fk_cod_client_quotes foreign key (cod_client) references clients(cod_client) on delete restrict,
  constraint fk_cod_device_quotes foreign key (cod_device) references devices(cod_device) on delete restrict,
  constraint fk_cod_document_status_quotes foreign key (cod_document_status) references document_status(cod_document_status) on delete restrict
);

-- 17. Ordenes de trabajo (OT)
create table if not exists work_orders (
  cod_work_order serial primary key,
  cod_client int not null,             -- El cliente principal, persona o emrpesa
  cod_contact int,                     -- El solicitante del trabajo, si es trabajador de una emrpesa
  cod_device int not null,
  cod_document_status int not null,    -- El estado del documento inicial (pendiente - Solo muestra categoría OT)

  -- diagnóstico inicial
  reported_issue text,                 -- "Dice que está lento"
  physical_condition text,             -- "Rayas en tapa, sin cargador"

  -- Diagnóstico técnico y solución
  technical_diagnosis text,            -- "Disco duro dañado"
  technical_report text,               -- "Se cambió disco, se instaló SO"
  start_date timestamp,                -- Fecha de apertura de la orden
  end_date timestamp,                  -- Fecha de cierre de la orden
  total_amount decimal(10, 2) default 0,
  created_at timestamp with time zone default current_timestamp,
  updated_at timestamp with time zone default current_timestamp,
  cod_user_updated_by int not null,

  constraint fk_cod_client_work_orders foreign key (cod_client) references clients(cod_client) on delete restrict,
  constraint fk_cod_contact_work_orders foreign key (cod_contact) references clients(cod_client) on delete set null,
  constraint fk_cod_device_work_orders foreign key (cod_device) references devices(cod_device) on delete restrict,
  constraint fk_cod_document_status_work_orders foreign key (cod_document_status) references document_status(cod_document_status) on delete restrict,
  constraint fk_cod_user_updated_by_work_orders foreign key (cod_user_updated_by) references users(cod_user) on delete restrict
);

-- 18. Detalles de la orden (Items: Productos o servicios utilizados)
-- Esta tabla vincula qué se usó en cada OT y a qué precio en dicho momento
create table if not exists work_order_items (
  cod_work_order_item serial primary key,
  cod_work_order int not null,
  
  -- Poliformismo simple: Puede ser producto o servicio
  cod_work_item_type int not null,      -- Tipo de item (producto/servicio/otros)
  cod_product int,                      -- Null si es servicio
  cod_service int,                      -- Null si es producto

  description varchar(255),             -- Copia del nombre para histórico
  quantity int default 1,
  unit_price decimal(10, 2) not null,   -- Precio congelado al momento de la orden
  sub_total decimal(10, 2) not null,
  created_at timestamp with time zone default current_timestamp,

  constraint check_item_type check ((cod_product is not null and cod_service is null) or (cod_product is null and cod_service is not null)),
  constraint check_work_order_items_qty_positive check (quantity > 0),
  constraint check_work_order_items_unit_price_positive check (unit_price >= 0),
  constraint check_work_order_items_subtotal_positive check (sub_total >= 0),

  constraint fk_cod_work_order_work_order_items foreign key (cod_work_order) references work_orders(cod_work_order) on delete cascade,
  constraint fk_cod_work_item_type_work_order_items foreign key (cod_work_item_type) references work_item_types(cod_work_item_type) on delete restrict,
  constraint fk_cod_product_work_order_item foreign key (cod_product) references products(cod_product) on delete restrict,
  constraint fk_cod_service_work_order_item foreign key (cod_service) references services(cod_service) on delete restrict
);


-- CONTABILIDAD SIMPLIFICADA
-- 19. Categoría de transacciones
create table if not exists transaction_categories (
  cod_transaction_category serial primary key,
  desc_transaction_category varchar(80) unique not null,
  cod_transaction_type int not null,
  created_at timestamp with time zone default current_timestamp,

  constraint fk_cod_transaction_type_transaction_categories foreign key (cod_transaction_type) references transaction_types(cod_transaction_type) on delete restrict
);

-- 20. Métodos de pago
create table if not exists payment_methods (
  cod_payment_method serial primary key,
  desc_payment_method varchar(80) unique not null,  -- efectivo, debito, credito, otros
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);

-- 21. Transacciones (Caja Chica / Flujo)
create table if not exists transactions (
  cod_transaction serial primary key,
  cod_transaction_type int not null,    -- Para saber si es ingreso, egreso u otros
  cod_transaction_category int not null,
  amount decimal(10, 2) not null,       -- Valor de la transacción
  cod_payment_method int not null,      -- Método de pago
  external_reference varchar(120),      -- Número de voucher, cheque, otros...
  description text,
  cod_work_order int,                   -- Identidicar la orden de trabajo
  cod_client int,                       -- Identificar el cliente
  cod_supplier int,                     -- Identificar el proveedor
  transaction_date timestamp with time zone default current_timestamp,

  constraint check_transactions_amount_positive check (amount >= 0),

  constraint fk_cod_transaction_type_transactions foreign key (cod_transaction_type) references transaction_types(cod_transaction_type) on delete restrict,
  constraint fk_cod_transaction_category_transactions foreign Key (cod_transaction_category) references transaction_categories(cod_transaction_category) on delete restrict,
  constraint fk_cod_payment_method_transactions foreign key (cod_payment_method) references payment_methods(cod_payment_method) on delete restrict,
  constraint fk_cod_work_order_transactions foreign key (cod_work_order) references work_orders(cod_work_order) on delete set null,
  constraint fk_cod_client_transactions foreign key (cod_client) references clients(cod_client) on delete set null,
  constraint fk_cod_supplier_transactions foreign key (cod_supplier) references suppliers(cod_supplier) on delete set null
);


-- ARCHIVOS ADJUNTOS
-- 22. Almacenamiento de archivos adjuntos (fotos, documentos, etc)
create table if not exists attachments (
  cod_attachment serial primary key,

  -- Poliformismo: puede estar asociado a diferentes entidades
  cod_entity_type int not null,            -- ID del tipo de entidad
  entity_id int not null,                  -- ID de la entidad relacionada

  -- Información del archivo
  original_filename varchar(255) not null,
  stored_filename varchar(255) not null,  -- Nombre único en el servidor
  file_path varchar(500) not null,        -- Ruta completa del archivo
  file_size bigint not null,              -- Tamaño en bytes
  mime_type varchar(100) not null,        -- image/jpeg, application/pdf, etc.
  
  -- Metadatos
  description text,                       -- Descripción opcional del archivo
  is_public boolean default false,        -- Si es visible para el cliente
  cod_user_uploaded_by int not null,      -- Usuario que subió el archivo
  created_at timestamp with time zone default current_timestamp,

  constraint fk_cod_entity_type_attachments foreign key (cod_entity_type) references entity_types(cod_entity_type) on delete restrict,
  constraint fk_cod_user_uploaded_by_attachments foreign key (cod_user_uploaded_by) references users(cod_user) on delete restrict
);


-- SISTEMA DE NOTIFICACIONES
-- 23. Sistema de notificaciones para el usuario
create table if not exists notifications (
  cod_notification serial primary key,

  -- Destinatario
  cod_user int not null,          -- Ususario que recibe la notificación

  -- Contenido
  title varchar(150) not null,    -- Titulo de la notificación
  message text not null,          -- Mensaje detallado de la notificación
  type varchar(50) not null,      -- Tipo de notificación

  -- Estado
  is_read boolean default false,
  read_at timestamp with time zone,

  -- Referencia opcional a entidad relacionada (ver como funcionaría)
  cod_entity_type int,            -- ID del tipo de entidad
  entity_id int,                  -- Id de la entidad

  -- Metadatos
  priority varchar(20) default 'normal',  -- 'low', 'normal', 'high', 'urgent'
  expires_at timestamp with time zone,    -- Fecha de expiración (opcional)
  created_at timestamp with time zone default current_timestamp,

  constraint fk_cod_user_notifications foreign key (cod_user) references users(cod_user) on delete cascade,
  constraint fk_cod_entity_type_notifications foreign key (cod_entity_type) references entity_types(cod_entity_type) on delete set null
);


-- CONFIGURACIONES SISTEMA
-- 24. Configuraciones del sistema
create table if not exists settings (
  cod_setting serial primary key,

  -- Identificaciones
  setting_key varchar(100) unique not null,   -- 'company_name', 'tax_rate', 'max_file_size'
  setting_group varchar(50) not null,         -- 'company', 'system', 'notifications', 'security'

  -- Valor
  setting_value text not null,                -- Valor como texto (jSON para estructuras complejas)
  data_type varchar(20) default 'string',     -- 'string', 'number', 'boolean', 'json'

  -- Metadatos
  description text,                           -- Descripción de para que sirve
  is_editable boolean default true,           -- Si puede ser editado desde la interfaz
  requires_restart boolean default false,     -- Si requiere reiniciar la app

  -- Auditoría
  cod_user_updated_by int,
  created_at timestamp with time zone default current_timestamp,
  updated_at timestamp with time zone default current_timestamp,

  constraint fk_cod_user_updated_by_settings foreign key (cod_user_updated_by) references users(cod_user) on delete set null
);


-- AUDITORÍA COMPLETA
-- 25. Log de auditoría para todas las operaciones
create table if not exists audit_logs (
  cod_audit_log serial primary key,

  -- Qué entidad fue afectada
  table_name varchar(100) not null,           -- 'work_orders', 'clients', 'devices'
  record_id int not null,                     -- ID del registro afectado

  -- Qué acción se realizó
  action varchar(20) not null,                -- 'INSERT', 'UPDATE', 'DELETE'
 
  -- Quién y cuándo
  cod_user int not null,                      -- Usuario que realizó la acción
  user_ip inet,                               -- IP del usuario
  user_agent text,                            -- Navegador/aplicación utilizada

  -- Datos del cambio
  old_values jsonb,                           -- Valores anteriores (para UPDATE y DELETE)
  new_values jsonb,                           -- Valores nuevos (para INSERT y UPDATE)
  changed_fields text[],                      -- Array con nombres de campos modificados

  -- Contexto adicional
  description text,                           -- Descripción opcional de la acción
  created_at timestamp with time zone default current_timestamp,

  constraint fk_cod_user_audit_logs foreign key (cod_user) references users(cod_user) on delete restrict
);


-- ETIQUETAS DEL SISTEMA
-- 26. Sistema de etiquetas para categorización flexible
create table if not exists tags (
  cod_tag serial primary key,
  desc_tag varchar(50) unique not null,       -- 'urgente', 'garantia', 'cliente_vip'
  color varchar(7) default '#6b7280',         -- Color hexadecimal para la interfaz
  description text,
  is_active boolean default true,
  created_at timestamp with time zone default current_timestamp
);


-- 27. Relación muchos a muchos entre entidades y tags
create table if not exists entity_tags (
  cod_entity_tag serial primary key,
  cod_tag int not null,

  -- Polimorfismo: puede ser aplicado a cualquier entidad
  cod_entity_type int not null,         -- ID del tipo de entidad
  entity_id int not null,

  cod_user_tagged_by int not null,      -- Usuario que aplicó la etiqueta
  created_at timestamp with time zone default current_timestamp,

  -- Evitar duplicados
  unique(cod_tag, cod_entity_type, entity_id),

  constraint fk_cod_tag_entity_tags foreign key (cod_tag) references tags(cod_tag) on delete cascade,
  constraint fk_cod_entity_type_entity_tags foreign key (cod_entity_type) references entity_types(cod_entity_type) on delete restrict,
  constraint fk_cod_user_tagged_by_entity_tags foreign key (cod_user_tagged_by) references users(cod_user) on delete restrict
);

-- ============================================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE RENDIMIENTO - POSTGRESQL
-- ============================================================================

-- FOREIGN KEYS (PostgreSQL los necesita para rendimiento)
CREATE INDEX idx_users_role ON users(cod_role);
CREATE INDEX idx_clients_type ON clients(cod_client_type);
CREATE INDEX idx_devices_client ON devices(cod_client);
CREATE INDEX idx_devices_type ON devices(cod_type_device);
CREATE INDEX idx_products_supplier ON products(cod_supplier);

-- WORK_ORDERS (tabla más consultada)
CREATE INDEX idx_work_orders_client ON work_orders(cod_client);
CREATE INDEX idx_work_orders_device ON work_orders(cod_device);
CREATE INDEX idx_work_orders_status ON work_orders(cod_document_status);
CREATE INDEX idx_work_orders_date ON work_orders(created_at);
-- Índice compuesto para dashboard (estados + fecha)
CREATE INDEX idx_work_orders_status_date ON work_orders(cod_document_status, created_at);

-- WORK_ORDER_ITEMS (para cargar detalles de manera eficiente)
CREATE INDEX idx_work_order_items_order ON work_order_items(cod_work_order);

-- TRANSACTIONS (para reportes financieros)
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_type ON transactions(cod_transaction_type);

-- BÚSQUEDAS FRECUENTES
CREATE INDEX idx_clients_email ON clients(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_clients_name ON clients(full_name);

-- POLIFORMISMO (Uso en adjuntos y etiquetas)
CREATE INDEX idx_attachments_entity ON attachments(cod_entity_type, entity_id);
CREATE INDEX idx_entity_tags_entity ON entity_tags(cod_entity_type, entity_id);

-- Para optimizar consultas con is_active
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = true;
CREATE INDEX idx_services_active ON services(is_active) WHERE is_active = true;
CREATE INDEX idx_suppliers_active ON suppliers(is_active) WHERE is_active = true;
CREATE INDEX idx_clients_active ON clients(is_active) WHERE is_active = true;
CREATE INDEX idx_devices_active ON devices(is_active) WHERE is_active = true;
