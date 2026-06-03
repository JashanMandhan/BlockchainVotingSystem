CREATE DATABASE IF NOT EXISTS blockchain_voting;
USE blockchain_voting;
CREATE TABLE roles (
  role_id     INT AUTO_INCREMENT PRIMARY KEY,
  role_name   VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;
CREATE TABLE users (
  user_id        INT AUTO_INCREMENT PRIMARY KEY,
  username       VARCHAR(100) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  salt           VARBINARY(16) NOT NULL,
  role_id        INT NOT NULL,
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  FOREIGN KEY (role_id) REFERENCES roles(role_id)
) ENGINE=InnoDB;
CREATE TABLE elections (
  election_id   INT AUTO_INCREMENT PRIMARY KEY,
  title         VARCHAR(100) NOT NULL,
  description   TEXT,
  start_time    DATETIME NOT NULL,
  end_time      DATETIME NOT NULL,
  created_by    INT NOT NULL,       -- who created or is managing the election
  public_key    TEXT,              -- optional: public key for vote encryption
  FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB;
CREATE TABLE candidates (
  candidate_id  INT AUTO_INCREMENT PRIMARY KEY,
  election_id   INT NOT NULL,
  name          VARCHAR(100) NOT NULL,
  details       TEXT,
  FOREIGN KEY (election_id) REFERENCES elections(election_id) ON DELETE CASCADE,
  UNIQUE (election_id, name)
) ENGINE=InnoDB;
CREATE TABLE eligible_voters (
  election_id   INT NOT NULL,
  user_id       INT NOT NULL,
  PRIMARY KEY (election_id, user_id),
  FOREIGN KEY (election_id) REFERENCES elections(election_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)   REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE votes (
  vote_id       INT AUTO_INCREMENT PRIMARY KEY,
  election_id   INT NOT NULL,
  voter_id      INT NOT NULL,
  candidate_id  INT NOT NULL,
  vote_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  vote_hash     CHAR(64) NOT NULL,   -- hash of this vote's data for integrity
  prev_hash     CHAR(64),           -- hash of the previous vote (chain link)
  encrypted_choice VARBINARY(256),  -- encrypted vote data for confidentiality
  -- Foreign key to ensure the voter was eligible for this election
  FOREIGN KEY (election_id, voter_id) REFERENCES eligible_voters(election_id, user_id),
  FOREIGN KEY (election_id)  REFERENCES elections(election_id) ON DELETE RESTRICT,
  FOREIGN KEY (voter_id)    REFERENCES users(user_id) ON DELETE RESTRICT,
  FOREIGN KEY (candidate_id) REFERENCES candidates(candidate_id) ON DELETE RESTRICT,
  UNIQUE (election_id, voter_id)
) ENGINE=InnoDB;
CREATE TABLE audit_log (
  log_id      INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT,
  action      VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50),
  entity_id   INT,
  timestamp   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  details     TEXT,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;




INSERT INTO roles (role_name) VALUES
  ('Admin'),
  ('ElectionOfficer'),
  ('Voter'),
  ('Auditor'),
  ('SuperUser');

INSERT INTO users (username, password_hash, salt, role_id, is_active) VALUES
  ('admin@example.com', 'hashed_admin_password', x'0102030405060708090A0B0C0D0E0F10', 1, 1),
  ('officer@example.com', 'hashed_officer_password', x'1112131415161718191A1B1C1D1E1F20', 2, 1),
  ('voter1@example.com', 'hashed_voter1_password', x'2122232425262728292A2B2C2D2E2F30', 3, 1),
  ('voter2@example.com', 'hashed_voter2_password', x'3132333435363738393A3B3C3D3E3F40', 3, 1),
  ('auditor@example.com', 'hashed_auditor_password', x'4142434445464748494A4B4C4D4E4F50', 4, 1);

INSERT INTO elections (title, description, start_time, end_time, created_by, public_key) VALUES
  ('General Election 2025', 'National general election for 2025', '2025-03-10 08:00:00', '2025-03-10 18:00:00', 1, 'publickey1'),
  ('City Council Election', 'Election for city council representatives', '2025-04-01 09:00:00', '2025-04-01 17:00:00', 2, 'publickey2'),
  ('School Board Election', 'Election for the local school board', '2025-05-05 10:00:00', '2025-05-05 16:00:00', 2, 'publickey3'),
  ('Corporate Board Election', 'Election for corporate board members', '2025-06-15 09:30:00', '2025-06-15 15:30:00', 1, 'publickey4'),
  ('Local Referendum', 'Vote on the local referendum issue', '2025-07-20 07:00:00', '2025-07-20 19:00:00', 1, 'publickey5');

INSERT INTO candidates (election_id, name, details) VALUES
  (1, 'Candidate A', 'Candidate A for General Election 2025'),
  (2, 'Candidate B', 'Candidate B for City Council Election'),
  (3, 'Candidate C', 'Candidate C for School Board Election'),
  (4, 'Candidate D', 'Candidate D for Corporate Board Election'),
  (5, 'Candidate E', 'Candidate E for Local Referendum');

INSERT INTO eligible_voters (election_id, user_id) VALUES
  (1, 3),
  (1, 4),
  (2, 3),
  (3, 4),
  (5, 3);

INSERT INTO votes (election_id, voter_id, candidate_id, vote_timestamp, vote_hash, prev_hash, encrypted_choice) VALUES
  (1, 3, 1, '2025-03-10 08:30:00', '1111111111111111111111111111111111111111111111111111111111111111', NULL, x'ABCDEF'),
  (1, 4, 1, '2025-03-10 08:35:00', '2222222222222222222222222222222222222222222222222222222222222222', '1111111111111111111111111111111111111111111111111111111111111111', x'123456'),
  (2, 3, 2, '2025-04-01 09:15:00', '3333333333333333333333333333333333333333333333333333333333333333', NULL, x'789ABC'),
  (3, 4, 3, '2025-05-05 10:30:00', '4444444444444444444444444444444444444444444444444444444444444444', NULL, x'DEF123'),
  (5, 3, 5, '2025-07-20 08:00:00', '5555555555555555555555555555555555555555555555555555555555555555', NULL, x'456789');

INSERT INTO audit_log (user_id, action, entity_type, entity_id, timestamp, details) VALUES
  (1, 'ELECTION_CREATED', 'Election', 1, '2025-03-01 10:00:00', 'General Election 2025 created by Admin'),
  (2, 'ELECTION_CREATED', 'Election', 2, '2025-03-15 11:00:00', 'City Council Election created by Officer'),
  (1, 'VOTE_CAST', 'Vote', 1, '2025-03-10 08:30:00', 'Vote cast by voter1 in General Election 2025'),
  (2, 'VOTE_CAST', 'Vote', 2, '2025-03-10 08:35:00', 'Vote cast by voter2 in General Election 2025'),
  (1, 'AUDIT_LOG_ENTRY', 'System', NULL, '2025-03-10 09:00:00', 'Audit log entry for initial votes');

select * from votes;
select * from audit_log;
select * from eligible_voters;
select * from candidates;
select * from elections;
select * from users;
select * from roles;

