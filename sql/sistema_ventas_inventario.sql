-- Script MySQL: Sistema de Ventas e Inventario
-- Incluye esquema completo, claves PK/FK autoincrementales y datos dummy.

DROP DATABASE IF EXISTS sistema_ventas_inventario;
CREATE DATABASE sistema_ventas_inventario
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sistema_ventas_inventario;

-- ============================================
-- 1) Tabla: usuarios
-- ============================================
CREATE TABLE usuarios (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol ENUM('admin','vendedor','almacenista') NOT NULL DEFAULT 'vendedor',
  estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- 2) Tabla: unidades_medida
-- ============================================
CREATE TABLE unidades_medida (
  id_unidad_medida INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL,
  abreviatura VARCHAR(10) NOT NULL UNIQUE,
  estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB;

-- ============================================
-- 3) Tabla: sucursales_ventas
-- ============================================
CREATE TABLE sucursales_ventas (
  id_sucursal INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  direccion VARCHAR(255) NOT NULL,
  telefono VARCHAR(30),
  ciudad VARCHAR(80) NOT NULL,
  estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- 4) Tabla: clientes
-- ============================================
CREATE TABLE clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombres VARCHAR(120) NOT NULL,
  apellidos VARCHAR(120) NOT NULL,
  documento_identidad VARCHAR(25) NOT NULL UNIQUE,
  email VARCHAR(150) UNIQUE,
  telefono VARCHAR(30),
  direccion VARCHAR(255),
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB;

-- ============================================
-- 5) Tabla: productos
-- ============================================
CREATE TABLE productos (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(40) NOT NULL UNIQUE,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  id_unidad_medida INT NOT NULL,
  precio_compra DECIMAL(12,2) NOT NULL CHECK (precio_compra >= 0),
  precio_venta DECIMAL(12,2) NOT NULL CHECK (precio_venta >= 0),
  stock_minimo INT NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
  estado ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_productos_unidad_medida
    FOREIGN KEY (id_unidad_medida)
    REFERENCES unidades_medida(id_unidad_medida)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================
-- 6) Módulo de inventarios: inventarios
-- ============================================
CREATE TABLE inventarios (
  id_inventario INT AUTO_INCREMENT PRIMARY KEY,
  id_sucursal INT NOT NULL,
  id_producto INT NOT NULL,
  stock_actual INT NOT NULL DEFAULT 0 CHECK (stock_actual >= 0),
  stock_reservado INT NOT NULL DEFAULT 0 CHECK (stock_reservado >= 0),
  stock_disponible INT GENERATED ALWAYS AS (stock_actual - stock_reservado) STORED,
  ultima_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_inventario_sucursal_producto UNIQUE (id_sucursal, id_producto),
  CONSTRAINT fk_inventarios_sucursal
    FOREIGN KEY (id_sucursal)
    REFERENCES sucursales_ventas(id_sucursal)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_inventarios_producto
    FOREIGN KEY (id_producto)
    REFERENCES productos(id_producto)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================
-- 7) Módulo de inventarios: movimientos_inventario
-- ============================================
CREATE TABLE movimientos_inventario (
  id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
  id_inventario INT NOT NULL,
  id_usuario INT NOT NULL,
  tipo_movimiento ENUM('entrada','salida','ajuste') NOT NULL,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  motivo VARCHAR(180) NOT NULL,
  referencia VARCHAR(100),
  fecha_movimiento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_movimientos_inventario
    FOREIGN KEY (id_inventario)
    REFERENCES inventarios(id_inventario)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_movimientos_usuario
    FOREIGN KEY (id_usuario)
    REFERENCES usuarios(id_usuario)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================
-- 8) Tabla: pedidos (cabecera)
-- ============================================
CREATE TABLE pedidos (
  id_pedido INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  id_usuario INT NOT NULL,
  id_sucursal INT NOT NULL,
  fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('pendiente','pagado','anulado') NOT NULL DEFAULT 'pendiente',
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  impuesto DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  observaciones VARCHAR(255),
  CONSTRAINT fk_pedidos_cliente
    FOREIGN KEY (id_cliente)
    REFERENCES clientes(id_cliente)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_pedidos_usuario
    FOREIGN KEY (id_usuario)
    REFERENCES usuarios(id_usuario)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_pedidos_sucursal
    FOREIGN KEY (id_sucursal)
    REFERENCES sucursales_ventas(id_sucursal)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================
-- 9) Tabla: pedido_detalle
-- ============================================
CREATE TABLE pedido_detalle (
  id_detalle INT AUTO_INCREMENT PRIMARY KEY,
  id_pedido INT NOT NULL,
  id_producto INT NOT NULL,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  precio_unitario DECIMAL(12,2) NOT NULL CHECK (precio_unitario >= 0),
  descuento DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (descuento >= 0),
  impuesto DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (impuesto >= 0),
  total_linea DECIMAL(12,2) NOT NULL CHECK (total_linea >= 0),
  CONSTRAINT uq_pedido_producto UNIQUE (id_pedido, id_producto),
  CONSTRAINT fk_detalle_pedido
    FOREIGN KEY (id_pedido)
    REFERENCES pedidos(id_pedido)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_detalle_producto
    FOREIGN KEY (id_producto)
    REFERENCES productos(id_producto)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================
-- DATOS DUMMY
-- ============================================

INSERT INTO usuarios (nombre, email, password_hash, rol, estado) VALUES
('Ana Torres', 'ana.torres@empresa.com', 'hash_demo_ana', 'admin', 'activo'),
('Luis Gómez', 'luis.gomez@empresa.com', 'hash_demo_luis', 'vendedor', 'activo'),
('Marta Díaz', 'marta.diaz@empresa.com', 'hash_demo_marta', 'almacenista', 'activo');

INSERT INTO unidades_medida (nombre, abreviatura, estado) VALUES
('Unidad', 'UND', 'activo'),
('Kilogramo', 'KG', 'activo'),
('Litro', 'L', 'activo'),
('Caja', 'CJ', 'activo');

INSERT INTO sucursales_ventas (nombre, direccion, telefono, ciudad, estado) VALUES
('Sucursal Centro', 'Av. Principal 123', '+1-555-1001', 'Ciudad Central', 'activo'),
('Sucursal Norte', 'Calle 45 #78-20', '+1-555-1002', 'Ciudad Norte', 'activo');

INSERT INTO clientes (nombres, apellidos, documento_identidad, email, telefono, direccion, estado) VALUES
('Carlos', 'Ramírez', 'DOC-10001', 'carlos.ramirez@mail.com', '+1-555-2001', 'Cra 10 #20-30', 'activo'),
('Laura', 'Mendoza', 'DOC-10002', 'laura.mendoza@mail.com', '+1-555-2002', 'Av 7 #11-90', 'activo'),
('Pedro', 'Santos', 'DOC-10003', 'pedro.santos@mail.com', '+1-555-2003', 'Calle 80 #45-12', 'activo');

INSERT INTO productos (sku, nombre, descripcion, id_unidad_medida, precio_compra, precio_venta, stock_minimo, estado) VALUES
('SKU-0001', 'Arroz Premium 1KG', 'Arroz blanco grano largo', 2, 1.20, 1.80, 30, 'activo'),
('SKU-0002', 'Aceite Vegetal 1L', 'Aceite para cocina', 3, 2.10, 3.20, 20, 'activo'),
('SKU-0003', 'Azúcar Blanca 1KG', 'Azúcar refinada', 2, 0.95, 1.50, 25, 'activo'),
('SKU-0004', 'Galletas Surtidas Caja', 'Caja de galletas surtidas', 4, 4.50, 6.90, 10, 'activo');

INSERT INTO inventarios (id_sucursal, id_producto, stock_actual, stock_reservado) VALUES
(1, 1, 120, 10),
(1, 2, 80, 5),
(1, 3, 95, 8),
(1, 4, 40, 4),
(2, 1, 70, 6),
(2, 2, 65, 4),
(2, 3, 50, 5),
(2, 4, 35, 3);

INSERT INTO movimientos_inventario (id_inventario, id_usuario, tipo_movimiento, cantidad, motivo, referencia) VALUES
(1, 3, 'entrada', 120, 'Carga inicial de stock', 'INI-ALM-001'),
(2, 3, 'entrada', 80, 'Carga inicial de stock', 'INI-ALM-002'),
(5, 3, 'entrada', 70, 'Carga inicial de stock', 'INI-ALM-003'),
(1, 2, 'salida', 10, 'Reserva por pedido', 'PED-0001'),
(3, 2, 'salida', 8, 'Reserva por pedido', 'PED-0002');

INSERT INTO pedidos (id_cliente, id_usuario, id_sucursal, estado, subtotal, impuesto, total, observaciones) VALUES
(1, 2, 1, 'pagado', 9.00, 1.08, 10.08, 'Pago con tarjeta'),
(2, 2, 1, 'pendiente', 6.50, 0.78, 7.28, 'Entrega en mostrador'),
(3, 2, 2, 'pagado', 8.70, 1.04, 9.74, 'Cliente frecuente');

INSERT INTO pedido_detalle (id_pedido, id_producto, cantidad, precio_unitario, descuento, impuesto, total_linea) VALUES
(1, 1, 2, 1.80, 0.00, 0.43, 4.03),
(1, 2, 1, 3.20, 0.00, 0.38, 3.58),
(1, 4, 1, 6.90, 0.00, 0.27, 6.17),
(2, 3, 3, 1.50, 0.00, 0.54, 5.04),
(2, 1, 1, 1.80, 0.00, 0.22, 2.02),
(3, 2, 2, 3.20, 0.50, 0.71, 6.61),
(3, 4, 1, 6.90, 0.00, 0.33, 7.23);

-- Consultas de verificación opcionales
-- SELECT * FROM usuarios;
-- SELECT * FROM inventarios;
-- SELECT p.id_pedido, c.nombres, c.apellidos, p.total FROM pedidos p JOIN clientes c ON c.id_cliente = p.id_cliente;
