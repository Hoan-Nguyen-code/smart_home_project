
/* SMART HOME DATABASE - SQL SERVER */

IF DB_ID(N'SmartHomeDB') IS NULL
BEGIN
    CREATE DATABASE SmartHomeDB;
END;
GO

USE SmartHomeDB;
GO

-- 1. USERS
CREATE TABLE dbo.users (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

-- 2. HOMES
CREATE TABLE dbo.homes (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    name NVARCHAR(100) NOT NULL
);

-- 3. HOME MEMBERS
CREATE TABLE dbo.home_members (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    home_id BIGINT NOT NULL,
    joined_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_home_members_user
        FOREIGN KEY (user_id) REFERENCES dbo.users(id),

    CONSTRAINT FK_home_members_home
        FOREIGN KEY (home_id) REFERENCES dbo.homes(id),

    CONSTRAINT UQ_home_members_user_home
        UNIQUE (user_id, home_id)
);

-- 4. HOME INVITATIONS
CREATE TABLE dbo.home_invitations (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    home_id BIGINT NOT NULL,
    created_by BIGINT NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    expires_at DATETIME2 NOT NULL,
    used_at DATETIME2 NULL,

    CONSTRAINT FK_home_invitations_home
        FOREIGN KEY (home_id) REFERENCES dbo.homes(id),

    CONSTRAINT FK_home_invitations_creator
        FOREIGN KEY (created_by) REFERENCES dbo.users(id)
);

-- 5. ROOMS
CREATE TABLE dbo.rooms (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    home_id BIGINT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(255) NULL,

    CONSTRAINT FK_rooms_home
        FOREIGN KEY (home_id) REFERENCES dbo.homes(id),

    CONSTRAINT UQ_rooms_home_name
        UNIQUE (home_id, name)
);

-- 6. IOT NODES (ESP32)
CREATE TABLE dbo.iot_nodes (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    room_id BIGINT NOT NULL,
    node_code VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'OFFLINE',
    last_seen_at DATETIME2 NULL,

    CONSTRAINT FK_iot_nodes_room
        FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),

    CONSTRAINT CK_iot_nodes_status
        CHECK (status IN ('ONLINE', 'OFFLINE'))
);

-- 7. DEVICES
CREATE TABLE dbo.devices (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    room_id BIGINT NOT NULL,
    node_id BIGINT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    status BIT NOT NULL DEFAULT 0,
    mqtt_channel VARCHAR(200) NOT NULL UNIQUE,

    CONSTRAINT FK_devices_room
        FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),

    CONSTRAINT FK_devices_node
        FOREIGN KEY (node_id) REFERENCES dbo.iot_nodes(id),

    CONSTRAINT CK_devices_type
        CHECK (type IN ('LIGHT', 'FAN'))
);

-- 8. SENSORS
CREATE TABLE dbo.sensors (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    room_id BIGINT NOT NULL,
    node_id BIGINT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    unit VARCHAR(20) NULL,

    CONSTRAINT FK_sensors_room
        FOREIGN KEY (room_id) REFERENCES dbo.rooms(id),

    CONSTRAINT FK_sensors_node
        FOREIGN KEY (node_id) REFERENCES dbo.iot_nodes(id),

    CONSTRAINT CK_sensors_type
        CHECK (type IN ('DHT22', 'BH1750', 'PIR'))
);

-- 9. SENSOR READINGS
CREATE TABLE dbo.sensor_readings (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    sensor_id BIGINT NOT NULL,
    metric VARCHAR(30) NOT NULL,
    value FLOAT NOT NULL,
    recorded_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_sensor_readings_sensor
        FOREIGN KEY (sensor_id) REFERENCES dbo.sensors(id),

    CONSTRAINT CK_sensor_readings_metric
        CHECK (metric IN (
            'TEMPERATURE',
            'HUMIDITY',
            'ILLUMINANCE',
            'MOTION'
        ))
);

CREATE INDEX IX_sensor_readings_sensor_time
ON dbo.sensor_readings(sensor_id, recorded_at DESC);

-- 10. AUTOMATION RULES
CREATE TABLE dbo.automation_rules (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    home_id BIGINT NOT NULL,
    name NVARCHAR(150) NOT NULL,
    enabled BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_automation_rules_home
        FOREIGN KEY (home_id) REFERENCES dbo.homes(id)
);

-- 11. RULE CONDITIONS
CREATE TABLE dbo.rule_conditions (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    rule_id BIGINT NOT NULL,
    sensor_id BIGINT NOT NULL,
    metric VARCHAR(30) NOT NULL,
    [operator] VARCHAR(4) NOT NULL,
    threshold FLOAT NOT NULL,

    CONSTRAINT FK_rule_conditions_rule
        FOREIGN KEY (rule_id)
        REFERENCES dbo.automation_rules(id)
        ON DELETE CASCADE,

    CONSTRAINT FK_rule_conditions_sensor
        FOREIGN KEY (sensor_id) REFERENCES dbo.sensors(id),

    CONSTRAINT CK_rule_conditions_metric
        CHECK (metric IN (
            'TEMPERATURE',
            'HUMIDITY',
            'ILLUMINANCE',
            'MOTION'
        )),

    CONSTRAINT CK_rule_conditions_operator
        CHECK ([operator] IN ('>', '>=', '<', '<=', '=', '!='))
);

-- 12. RULE ACTIONS
CREATE TABLE dbo.rule_actions (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    rule_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    target_state BIT NOT NULL,

    CONSTRAINT FK_rule_actions_rule
        FOREIGN KEY (rule_id)
        REFERENCES dbo.automation_rules(id)
        ON DELETE CASCADE,

    CONSTRAINT FK_rule_actions_device
        FOREIGN KEY (device_id) REFERENCES dbo.devices(id)
);

-- 13. ANOMALY DETECTIONS
CREATE TABLE dbo.anomaly_detections (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    reading_id BIGINT NOT NULL,
    anomaly_score FLOAT NOT NULL,
    is_anomaly BIT NOT NULL,
    detected_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_anomaly_detections_reading
        FOREIGN KEY (reading_id)
        REFERENCES dbo.sensor_readings(id)
);

CREATE INDEX IX_anomaly_detections_reading
ON dbo.anomaly_detections(reading_id);

-- 14. ANOMALY ALERTS
CREATE TABLE dbo.anomaly_alerts (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    detection_id BIGINT NOT NULL UNIQUE,
    severity VARCHAR(20) NOT NULL,
    message NVARCHAR(500) NOT NULL,
    is_read BIT NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_anomaly_alerts_detection
        FOREIGN KEY (detection_id)
        REFERENCES dbo.anomaly_detections(id),

    CONSTRAINT CK_anomaly_alerts_severity
        CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH'))
);
GO

/* ==========================================
   DỮ LIỆU MẪU CHO PHẦN CỨNG DEMO
   ========================================== */

-- Tạo 1 ngôi nhà
INSERT INTO dbo.homes(name)
VALUES (N'Nhà thông minh');

DECLARE @home_id BIGINT = SCOPE_IDENTITY();

-- Tạo 2 phòng
INSERT INTO dbo.rooms(home_id, name, description)
VALUES
    (@home_id, N'Phòng khách', N'Phòng khách - ESP32 số 1'),
    (@home_id, N'Phòng ngủ', N'Phòng ngủ - ESP32 số 2');

DECLARE @living BIGINT = (
    SELECT id FROM dbo.rooms
    WHERE home_id = @home_id AND name = N'Phòng khách'
);

DECLARE @bedroom BIGINT = (
    SELECT id FROM dbo.rooms
    WHERE home_id = @home_id AND name = N'Phòng ngủ'
);

-- Tạo 2 ESP32
INSERT INTO dbo.iot_nodes(room_id, node_code, status)
VALUES
    (@living, 'ESP32_LIVING', 'OFFLINE'),
    (@bedroom, 'ESP32_BEDROOM', 'OFFLINE');

DECLARE @living_node BIGINT = (
    SELECT id FROM dbo.iot_nodes
    WHERE node_code = 'ESP32_LIVING'
);

DECLARE @bedroom_node BIGINT = (
    SELECT id FROM dbo.iot_nodes
    WHERE node_code = 'ESP32_BEDROOM'
);

-- Tạo 3 thiết bị: 2 đèn và 1 quạt
INSERT INTO dbo.devices(
    room_id, node_id, name, type, status, mqtt_channel
)
VALUES
    (@living, @living_node,
     N'Đèn phòng khách', 'LIGHT', 0,
     'smarthome/living/light1/set'),

    (@bedroom, @bedroom_node,
     N'Đèn phòng ngủ', 'LIGHT', 0,
     'smarthome/bedroom/light1/set'),

    (@bedroom, @bedroom_node,
     N'Quạt phòng ngủ', 'FAN', 0,
     'smarthome/bedroom/fan1/set');

-- Tạo 6 cảm biến: mỗi phòng 3 cảm biến
INSERT INTO dbo.sensors(
    room_id, node_id, name, type, unit
)
VALUES
    (@living, @living_node,
     N'DHT22 phòng khách', 'DHT22', NULL),

    (@living, @living_node,
     N'BH1750 phòng khách', 'BH1750', 'lux'),

    (@living, @living_node,
     N'PIR phòng khách', 'PIR', NULL),

    (@bedroom, @bedroom_node,
     N'DHT22 phòng ngủ', 'DHT22', NULL),

    (@bedroom, @bedroom_node,
     N'BH1750 phòng ngủ', 'BH1750', 'lux'),

    (@bedroom, @bedroom_node,
     N'PIR phòng ngủ', 'PIR', NULL);
GO

/* KIỂM TRA DỮ LIỆU */
SELECT 'homes' AS table_name, COUNT(*) AS row_count
FROM dbo.homes

UNION ALL
SELECT 'rooms', COUNT(*) FROM dbo.rooms

UNION ALL
SELECT 'iot_nodes', COUNT(*) FROM dbo.iot_nodes

UNION ALL
SELECT 'devices', COUNT(*) FROM dbo.devices

UNION ALL
SELECT 'sensors', COUNT(*) FROM dbo.sensors;


/*Kiểm tra thông tin*/
SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
WHERE fk.referenced_object_id = OBJECT_ID('dbo.rooms');


SELECT
    r.id,
    r.name,
    (SELECT COUNT(*)
     FROM dbo.iot_nodes n
     WHERE n.room_id = r.id) AS SoESP32,
    (SELECT COUNT(*)
     FROM dbo.devices d
     WHERE d.room_id = r.id) AS SoThietBi,
    (SELECT COUNT(*)
     FROM dbo.sensors s
     WHERE s.room_id = r.id) AS SoCamBien
FROM dbo.rooms r
ORDER BY r.id;


USE SmartHomeDB;
GO

SELECT
    t.name AS TableName,
    c.column_id AS ColumnOrder,
    c.name AS ColumnName,
    ty.name AS DataType,
    CASE
        WHEN pk.column_id IS NOT NULL THEN 'PK'
        ELSE ''
    END AS PrimaryKey,
    CASE
        WHEN c.is_nullable = 1 THEN 'YES'
        ELSE 'NO'
    END AS IsNullable
FROM sys.tables t
JOIN sys.columns c
    ON c.object_id = t.object_id
JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.indexes i
    JOIN sys.index_columns ic
        ON i.object_id = ic.object_id
       AND i.index_id = ic.index_id
    WHERE i.is_primary_key = 1
) pk
    ON pk.object_id = c.object_id
   AND pk.column_id = c.column_id
ORDER BY t.name, c.column_id;

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fkc.parent_object_id) AS FromTable,
    pc.name AS FromColumn,
    OBJECT_NAME(fkc.referenced_object_id) AS ToTable,
    rc.name AS ToColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns pc
    ON pc.object_id = fkc.parent_object_id
   AND pc.column_id = fkc.parent_column_id
JOIN sys.columns rc
    ON rc.object_id = fkc.referenced_object_id
   AND rc.column_id = fkc.referenced_column_id
ORDER BY FromTable, ForeignKeyName;


USE SmartHomeDB;

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'devices'
ORDER BY ORDINAL_POSITION;


USE SmartHomeDB;

SELECT
    id,
    room_id,
    node_id,
    name,
    type,
    status,
    mqtt_channel
FROM devices
ORDER BY room_id, id;


USE SmartHomeDB;

SELECT
    id,
    name,
    status
FROM devices
ORDER BY id;

USE SmartHomeDB;

SELECT
    id,
    name,
    type,
    status
FROM devices
ORDER BY id;

USE SmartHomeDB;

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;

USE SmartHomeDB;

ALTER TABLE users
ADD role VARCHAR(20) NOT NULL
    CONSTRAINT DF_users_role DEFAULT 'USER';

ALTER TABLE users
ADD CONSTRAINT CK_users_role
CHECK (role IN ('ADMIN', 'USER'));

USE SmartHomeDB;

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'users'
  AND COLUMN_NAME = 'role';

  USE SmartHomeDB;
GO

ALTER TABLE users
ADD role VARCHAR(20) NOT NULL
    CONSTRAINT DF_users_role DEFAULT 'USER';
GO

ALTER TABLE users
ADD CONSTRAINT CK_users_role
CHECK (role IN ('ADMIN', 'USER'));
GO



/*USE SmartHomeDB;
GO

INSERT INTO dbo.users (
    full_name,
    email,
    password_hash,
    role,
    created_at
)
VALUES (
    N'Quản trị viên',
    'proem98@gmail.com',
    '$2a$10$GiCsyYSmZQtidCzhBW65XeuqHGLOMrLyxUavcG/nuqLPP.rrJ5siG ',
    'ADMIN',
    SYSDATETIME()
);

SELECT id, full_name, email, role, created_at
FROM dbo.users
WHERE role = 'ADMIN';*/

USE SmartHomeDB;
GO

SELECT
    id,
    email,
    role,
    LEN(password_hash) AS hash_length,
    LEFT(password_hash, 4) AS hash_prefix
FROM dbo.users
WHERE role = 'ADMIN';


USE SmartHomeDB;
GO

SELECT
    id,
    LEN(password_hash) AS hash_length,
    DATALENGTH(password_hash) AS byte_length,
    CASE
        WHEN password_hash COLLATE Latin1_General_BIN2
             LIKE '$2a$[0-9][0-9]$%'
         AND LEN(password_hash) = 60
         AND SUBSTRING(password_hash, 8, 53)
             COLLATE Latin1_General_BIN2
             NOT LIKE '%[^./A-Za-z0-9]%'
        THEN 'FORMAT_OK'
        ELSE 'FORMAT_INVALID'
    END AS bcrypt_format
FROM dbo.users
WHERE role = 'ADMIN';


USE SmartHomeDB;
GO

SELECT
    id,
    DATALENGTH(password_hash) AS before_bytes,
    DATALENGTH(RTRIM(password_hash)) AS after_bytes
FROM dbo.users
WHERE role = 'ADMIN';


UPDATE dbo.users
SET password_hash = RTRIM(password_hash)
WHERE role = 'ADMIN'
  AND DATALENGTH(password_hash) >
      DATALENGTH(RTRIM(password_hash));



USE SmartHomeDB;
GO

UPDATE dbo.users
SET password_hash = '$2a$10$SXRKv/gX12ivMg1XyH2ovump3DIp3nGw7UEfiMGGtqyH6zUkvERBy'
WHERE id = 1
  AND role = 'ADMIN';

SELECT
    id,
    role,
    LEN(password_hash) AS hash_length,
    DATALENGTH(password_hash) AS byte_length,
    LEFT(password_hash, 4) AS hash_prefix
FROM dbo.users
WHERE id = 1;



USE SmartHomeDB;
GO

INSERT INTO dbo.users (
    full_name,
    email,
    password_hash,
    role,
    created_at
)
VALUES (
    N'Người dùng kiểm thử',
    'user.test@smarthome.local',
    '$2a$10$MfS/gzjCORuOGRJNKN6rQeigmAbniTpZ97pCotnX7CDmq6gxFH1FG',
    'USER',
    SYSDATETIME()
);

SELECT
    id,
    email,
    role,
    LEN(password_hash) AS hash_length,
    DATALENGTH(password_hash) AS byte_length
FROM dbo.users
WHERE email = 'user.test@smarthome.local';


SELECT
    id,
    home_id,
    created_by,
    code,
    expires_at,
    used_at
FROM dbo.home_invitations
ORDER BY id DESC;


SELECT
    hm.id,
    u.full_name,
    u.email,
    hm.home_id,
    h.name AS home_name,
    hm.joined_at
FROM dbo.home_members hm
JOIN dbo.users u ON hm.user_id = u.id
JOIN dbo.homes h ON hm.home_id = h.id
ORDER BY hm.id DESC;


/*test ma het han*/
UPDATE dbo.home_invitations
SET expires_at = DATEADD(HOUR, -1, SYSUTCDATETIME())
WHERE code = 'BVCSRNBMLXQP'
  AND used_at IS NULL;

  USE SmartHomeDB;
GO

SELECT
    id,
    room_id,
    node_code,
    status,
    last_seen_at
FROM dbo.iot_nodes;