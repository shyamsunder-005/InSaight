-- Patient General Practitioner Table
CREATE TABLE patient_general_practitioner ( -- for referncing purpose only not permananent
    id              INT AUTO_INCREMENT PRIMARY KEY,
    patient_id      VARCHAR(64) NOT NULL,
    practitioner_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_prac_patient FOREIGN KEY (patient_id) REFERENCES patient(id),
    CONSTRAINT fk_practitioner FOREIGN KEY (practitioner_id) REFERENCES practitioner(id)
);

-- Practitioner Table
CREATE TABLE practitioner (
    id VARCHAR(64) NOT NULL PRIMARY KEY,
    given_name VARCHAR(100),
    family_name VARCHAR(100),
    gender VARCHAR(32),
    birth_date DATE,
    phone VARCHAR(50),
    email VARCHAR(100),
    active BOOLEAN DEFAULT TRUE
); -- 15 tables

-- Organization Table
CREATE TABLE organisation (
    id          VARCHAR(64) NOT NULL PRIMARY KEY,
    `name`        VARCHAR(255) NOT NULL,
    `type`        VARCHAR(128),
    address     VARCHAR(255),
    phone       VARCHAR(50),
    email       VARCHAR(100),
    active      BOOLEAN DEFAULT TRUE
);

---


CREATE TABLE codeable_concept ( -- like look up table
  concept_type VARCHAR(50) NOT NULL,              -- E.g., 'maritalStatus', 'identifier.type', 'relationship'
  `code` VARCHAR(32) NOT NULL,                    -- E.g., 'M'
  `system` VARCHAR(255),                 -- E.g., 'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus'
  display VARCHAR(255),                  -- E.g., 'Married'
  `text` VARCHAR(255),                   -- Optional free text if provided
  PRIMARY KEY (concept_type, `code`)       -- Composite primary key
);


-- Patient Table ---
CREATE TABLE patient (
    id                      VARCHAR(64)     NOT NULL PRIMARY KEY,   -- FHIR resource id (UUID or similar)
    active                  BOOLEAN         NOT NULL,               -- active status of the patient record (FHIR: active)
    gender                  varchar(32) NOT NULL,                                 -- Administrative gender (FHIR: gender) M,F
    birth_date               DATE,                                       -- Date of birth (FHIR: birthDate)
    
    deceased_boolean         BOOLEAN,                                    -- True if patient is deceased (FHIR: deceasedBoolean)
    deceased_dateTime        DATETIME,                                   -- DateTime of death, if known (FHIR: deceasedDateTime)
    
    marital_status_code     varchar(32),                                -- Marital status code (FHIR: maritalStatus coding)
    multiple_birth_boolean    BOOLEAN,                                    -- True if part of multiple birth (FHIR: multipleBirthBoolean)
    multiple_birth_integer    INT,                                        -- Birth order if multiple birth (FHIR: multipleBirthInteger)
    
    managing_organization_id VARCHAR(64),                                -- FK to Organization(id); custodian organization
    CONSTRAINT fk_patient_org FOREIGN KEY (managing_organization_id) REFERENCES organisation(id)
);

-- Patient Identifier Table
CREATE TABLE patient_identifier (
    patient_id    VARCHAR(64) NOT NULL,              -- FK to Patient(id)
    `use`         VARCHAR(32),                        -- Identifier use (official, usual, etc.)
    type_code     VARCHAR(32),                        -- Identifier type code (FHIR: Identifier.type coding) 	Driver's license number
    `system`      VARCHAR(128),                       -- Namespace for identifier (URI or OID)
    `value`       VARCHAR(128) NOT NULL,              -- Identifier value
    period_start  DATE,                               -- Identifier valid period start
    period_end    DATE,                               -- Identifier valid period end
	photo_attachment_id   INT UNIQUE,                -- FK to Attachment(id), 1 photo per identifier
    assigner_id VARCHAR(64),                       -- Assigner (e.g., reference to Organization)
    PRIMARY KEY (patient_id, `system`, `value`),     -- Composite PK ensures uniqueness per system+value
    CONSTRAINT fk_identifier_patient FOREIGN KEY (patient_id) REFERENCES patient(id),
	CONSTRAINT fk_patient_identifier_attachment FOREIGN KEY (photo_attachment_id) REFERENCES attachment(id),
	CONSTRAINT fk_patient_identifier_assigner FOREIGN KEY (assigner_id) REFERENCES organisation(id)
);

--  attachment where abha card will be saved 
CREATE TABLE attachment (
    id              INT AUTO_INCREMENT PRIMARY KEY,  -- Unique ID for attachment
    content_type    VARCHAR(64) NOT NULL,            -- MIME type, e.g., 'image/jpeg'
    url             TEXT,                            -- URL if stored externally
    `data`          MEDIUMBLOB,                        -- Inline binary data (photo)
    title           VARCHAR(128),                    -- Title of the attachment
	size            INT,                             -- File size in bytes
    `hash`          VARBINARY(20),                   -- SHA-1 hash (20 bytes)
    creation_date   DATETIME                         -- Timestamp of creation
);


-- Patient Name Table
CREATE TABLE patient_name (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  patient_id   VARCHAR(64) NOT NULL,
  `use`        varchar(32),
  `text`       VARCHAR(200),
  family       VARCHAR(100),
  given        VARCHAR(100),
  prefix       VARCHAR(50),
  suffix       VARCHAR(50),
  period_start DATE,
  period_end   DATE,
  CONSTRAINT fk_name_patient FOREIGN KEY (patient_id) REFERENCES patient(id)
);

-- Patient Telecom Table
CREATE TABLE patient_telecom (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  patient_id   VARCHAR(64) NOT NULL,
  `system`    VARCHAR(32),
  `value`      VARCHAR(100),
  `use`        VARCHAR(32),
  `rank`       INT,
  period_start DATE,
  period_end   DATE,
  CONSTRAINT fk_telecom_patient FOREIGN KEY (patient_id) REFERENCES patient(id)
);

-- Patient Address Table
CREATE TABLE patient_address (
  address_id   INT AUTO_INCREMENT PRIMARY KEY,
  patient_id   VARCHAR(64) NOT NULL,
  `use`          VARCHAR(32), -- ('home','work','temp','old','billing')
  `type`         VARCHAR(32), -- ('postal','physical','both'),
  `text`         VARCHAR(200),
  line1       VARCHAR(100),
  line2       VARCHAR(100),
  city         VARCHAR(100),
  district     VARCHAR(100),
  state        VARCHAR(100),
  postal_code  VARCHAR(20),
  country      VARCHAR(50),
  period_start DATE,
  period_end   DATE,
  CONSTRAINT fk_address_patient FOREIGN KEY (patient_id) REFERENCES patient(id)
);

-- Patient Contact Table
CREATE TABLE patient_contact ( -- can have multiple person for contacts
  id              INT AUTO_INCREMENT PRIMARY KEY,
  patient_id      VARCHAR(64) NOT NULL,
  name_text       VARCHAR(128),
  gender          VARCHAR(32), -- ('male','female','other','unknown')
  organization_id VARCHAR(64),
  period_start    DATE,
  period_end      DATE,
  CONSTRAINT fk_contact_patient FOREIGN KEY (patient_id) REFERENCES patient(id),
  CONSTRAINT fk_contact_org FOREIGN KEY (organization_id) REFERENCES organisation(id)
);

-- Patient Contact Relationship Table
CREATE TABLE patient_contact_relationship ( --  can have more like billing person and employer 
    id          INT AUTO_INCREMENT PRIMARY KEY,
    contact_id  INT NOT NULL,
    `code`      VARCHAR(32) NOT NULL,
    CONSTRAINT fk_crel_contact FOREIGN KEY (contact_id) REFERENCES patient_contact(id)
);

-- Patient Contact Telecom Table
CREATE TABLE patient_contact_telecom ( -- can have mutiple communication modes
    id          INT AUTO_INCREMENT PRIMARY KEY,
    contact_id  INT NOT NULL,
    `system`    VARCHAR(32), -- ('phone','fax','email','pager','url','sms','other'),
    `value`     VARCHAR(128) NOT NULL,
    `use`       VARCHAR(32),  -- ('home','work','temp','old','mobile'),
    `rank`      INT UNSIGNED,
    period_start DATE,
    period_end   DATE,
    CONSTRAINT fk_ctelecom_contact FOREIGN KEY (contact_id) REFERENCES patient_contact(id)
);

-- Patient Contact Address Table
CREATE TABLE patient_contact_address ( -- can have multiple homes of contact person
    id          INT AUTO_INCREMENT PRIMARY KEY,
    contact_id  INT NOT NULL,
    `use`       VARCHAR(32),  -- ('home','work','temp','old','billing'),
    `type`      VARCHAR(32), -- ('postal','physical','both')
    `text`      TEXT,
    line1       VARCHAR(128),
    line2       VARCHAR(128),
    city        VARCHAR(64),
    district    VARCHAR(64),
    state       VARCHAR(64),
    postal_code VARCHAR(20),
    country     VARCHAR(64),
    period_start DATE,
    period_end   DATE,
    CONSTRAINT fk_caddr_contact FOREIGN KEY (contact_id) REFERENCES patient_contact(id)
);

-- Patient Communication Table
CREATE TABLE patient_communication ( -- a patient can prefer multiple languages which he may prefer
    id              INT AUTO_INCREMENT PRIMARY KEY,
    patient_id      VARCHAR(64) NOT NULL,
    language_code   VARCHAR(32) NOT NULL,
    preferred       BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_comm_patient FOREIGN KEY (patient_id) REFERENCES patient(id)
);

-- Patient Link Table
CREATE TABLE patient_link (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    patient_id        VARCHAR(64) NOT NULL,
    other_patient_id  VARCHAR(64) NOT NULL,
    `type`            VARCHAR(32), -- 'replaced-by','replaces','refer','seealso') NOT NULL,
    CONSTRAINT fk_link_patient FOREIGN KEY (patient_id) REFERENCES patient(id),
    CONSTRAINT fk_link_other FOREIGN KEY (other_patient_id) REFERENCES patient(id)
);


