CREATE TABLE IF NOT EXISTS loot_prop_ressource (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    required INT NOT NULL,
    items TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS loot_prop_looting (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    required INT NOT NULL,
    items TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS loot_prop_recuperable (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    required INT NOT NULL,
    items TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS loot_prop_zone (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    required INT NOT NULL,
    items TEXT NOT NULL
);
