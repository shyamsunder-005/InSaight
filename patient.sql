create database insaights_db;
use insaights_db;
drop database insaights_db;
-- 16 tables total

-- Practitioner Table
CREATE TABLE insaights_practitioner (
  	id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()), 
    given_name VARCHAR(100),
    family_name VARCHAR(100),
    gender VARCHAR(32),
    birth_date DATE,
    phone VARCHAR(50),
    email VARCHAR(100),
    `active` BOOLEAN DEFAULT TRUE
); 

-- Organization Table
CREATE TABLE insaights_organisation (
	id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()), 
    `name`        VARCHAR(255) NOT NULL,
    `type`        VARCHAR(128),
    address     VARCHAR(255),
    phone       VARCHAR(50),
    email       VARCHAR(100),
    `active`      BOOLEAN DEFAULT TRUE
);

-- PractitionerRole Table
CREATE TABLE insaights_practitioner_role (
  	id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()), 
    practitioner_id     VARCHAR(64),                        -- Reference to Practitioner
    organization_id     VARCHAR(64),                        -- Reference to Organization
    `role`                VARCHAR(100),                       -- e.g., Doctor, Nurse, Surgeon
    specialty           VARCHAR(100),                       -- e.g., Cardiology, Pediatrics
    contact_number      VARCHAR(50),                        -- Phone or mobile
    email               VARCHAR(100),                       -- Email address
    available_start     DATETIME,                           -- Availability start time
    available_end       DATETIME,                           -- Availability end time
    `active`              BOOLEAN DEFAULT TRUE,               -- Whether currently active
    notes               TEXT                                -- Any additional notes
);


-- Patient General Practitioner Table
CREATE TABLE insaights_general_practitioner ( -- for referncing purpose only not permananent
    id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()), -- can reference to many practitioner
    
    organisation_id VARCHAR(64),
    practitioner_id VARCHAR(64),
    practitioner_role_id VARCHAR(64),
	patient_id      VARCHAR(64) NOT NULL,
    CONSTRAINT fk_prac_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
	CONSTRAINT fk_org_patient FOREIGN KEY (organisation_id) REFERENCES insaights_organisation(id),
    CONSTRAINT fk_org_patient_role FOREIGN KEY (practitioner_role_id) REFERENCES insaights_practitioner_role(id),
    CONSTRAINT fk_practitioner FOREIGN KEY (practitioner_id) REFERENCES insaights_practitioner(id),
    
    CONSTRAINT chk_only_one_reference CHECK (
		(practitioner_id IS NOT NULL AND organisation_id IS NULL AND practitioner_role_id IS NULL) OR
		(practitioner_id IS NULL AND organisation_id IS NOT NULL AND practitioner_role_id IS NULL) OR
		(practitioner_id IS NULL AND organisation_id IS NULL AND practitioner_role_id IS NOT NULL)
	)
);


CREATE TABLE insaights_related_person (
  id                  VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),  -- Unique FHIR resource ID
  patient_id          VARCHAR(64) NOT NULL,                      -- Reference to Patient
  name_text           VARCHAR(128),                              -- Full name
  relationship_code   VARCHAR(64),                               -- Type of relationship (e.g., mother, spouse)
  gender              VARCHAR(32),                               -- male | female | other | unknown
  birth_date          DATE,                                      -- Date of birth
  telecom             VARCHAR(128),                              -- Contact (phone/email)
  address             TEXT,                                      -- Address
  `active`              BOOLEAN DEFAULT TRUE,                      -- Whether this record is active
  period_start        DATE,                                      -- Valid from
  period_end          DATE,                                      -- Valid until
  created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,        -- Record creation timestamp

  CONSTRAINT fk_related_person_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
);

--  attachment where abha card will be saved 
CREATE TABLE insaights_attachment ( -- patient photo and other pictures are stored
	id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),  	 -- Unique ID for attachment
    content_type    VARCHAR(64),            -- MIME type, e.g., 'image/jpeg'
    `language`      VARCHAR(32),                     -- what language a pdf is written codeable concept
    url             TEXT,                            -- URL if stored externally
    `data`          MEDIUMBLOB,                        -- Inline binary data (photo)
    title           VARCHAR(128),                    -- Title of the attachment
	size            INT,                             -- File size in bytes
    `hash`          VARBINARY(20),                   -- SHA-1 hash (20 bytes)
    creation_date   DATETIME                         -- Timestamp of creation
);

-- Patient Table ---
CREATE TABLE insaights_patient (
	id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),   -- FHIR resource id (UUID or similar)
    
    -- human name table flattened
	name_prefix              VARCHAR(50),        -- FHIR: HumanName.prefix (e.g., 'Dr.')    
    first_name               VARCHAR(50),        -- FHIR: HumanName.given[0]
    middle_name              VARCHAR(50),        -- FHIR: HumanName.given[1] (optional)
    last_name                VARCHAR(100),       -- FHIR: HumanName.family
    name_suffix              VARCHAR(50),        -- FHIR: HumanName.suffix (e.g., 'PhD')
    full_name                VARCHAR(200),       -- FHIR: HumanName.text (full display name)
    
    `active`                 BOOLEAN,               -- active status of the patient record (FHIR: active) important for interpretation
    
    gender                   VARCHAR(32),                    -- Administrative gender (FHIR: gender) M,F
    birth_date               DATE,                                    -- Date of birth (FHIR: birthDate)
    
    deceased_boolean         BOOLEAN,                                 -- True if patient is deceased (FHIR: deceasedBoolean)important for interpretation
    deceased_dateTime        DATETIME,                                -- DateTime of death, if known (FHIR: deceasedDateTime) important for interpretation
    
    marital_status_code      VARCHAR(32),                            -- Marital status code (FHIR: maritalStatus coding) if child is part of multiple birth
    
    multiple_birth_boolean   BOOLEAN,                                -- True if part of multiple birth (FHIR: multipleBirthBoolean)
    multiple_birth_integer   INT,                                    -- Birth order if multiple birth (FHIR: multipleBirthInteger)
    
    photo  					 VARCHAR(64),							  -- photo_id
    religion				 VARCHAR(32),                              -- for storing reliigion special case
    annual_income			 INT,										-- for storing annual income
    nationality				 VARCHAR(32),								-- for nationality
	created_at               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- Creation timestamp
    
    managing_organization_id VARCHAR(64) ,-- FK to Organization(id); custodian organization
	CONSTRAINT fk_patient_attachment FOREIGN KEY (photo) REFERENCES insaights_attachment(id),
    CONSTRAINT fk_patient_org FOREIGN KEY (managing_organization_id) REFERENCES insaights_organisation(id)
);

-- Patient Identifier Table
CREATE TABLE insaights_identifier ( -- must strong participation
	id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()), 
    `use`         VARCHAR(32),                        -- Identifier use (official, usual, etc.)
    type_code     VARCHAR(32),                        -- Identifier type code (FHIR: Identifier.type coding) 	Driver's license number
    `system`      VARCHAR(128),                       -- Namespace for identifier (URI or OID)
    `value`       VARCHAR(128),              -- Identifier value
    period_start  DATE,                               -- Identifier valid period start
    period_end    DATE,                               -- Identifier valid period end
	photo_attachment_id   VARCHAR(64),                -- FK to Attachment(id), 1 photo per identifier
    assigner_id VARCHAR(64),                       -- Assigner (e.g., reference to Organization)
    
    -- PRIMARY KEY (patient_id, `system`, `value`),     -- Composite PK ensures uniqueness per system+value
	patient_id    VARCHAR(64) NOT NULL,              -- FK to Patient(id)
    CONSTRAINT fk_identifier_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
	CONSTRAINT fk_patient_identifier_attachment FOREIGN KEY (photo_attachment_id) REFERENCES insaights_attachment(id),
	CONSTRAINT fk_patient_identifier_assigner FOREIGN KEY (assigner_id) REFERENCES insaights_organisation(id)
);

-- A contact detail for the individual patient
CREATE TABLE insaights_telecom (
  id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),
  `system`    VARCHAR(32), -- phone, email
  `value`      VARCHAR(100), -- actual address like ohone number
  `use`        VARCHAR(32), -- work, home
  `rank`       INT UNSIGNED, -- which is of highest prioprity
  period_start DATE,
  period_end   DATE,
  
  patient_id   VARCHAR(64) NOT NULL,
  CONSTRAINT fk_telecom_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
);

-- Patient Address Table
CREATE TABLE insaights_address (
  id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),
  `use`          VARCHAR(32), -- ('home','work','temp','old','billing')
  `type`         VARCHAR(32), -- ('postal','physical','both'),
  `text`         VARCHAR(200), -- address
  line1       VARCHAR(100),
  line2       VARCHAR(100),
  city         VARCHAR(100),
  district     VARCHAR(100),
  state        VARCHAR(100),
  postal_code  VARCHAR(20),
  country      VARCHAR(50),
  period_start DATE,
  period_end   DATE,
  
  patient_id   VARCHAR(64) NOT NULL,
  CONSTRAINT fk_address_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
);

-- Patient Contact Table
CREATE TABLE insaights_contact ( -- can have multiple person for contacts
  id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),
  
  name_prefix              VARCHAR(50),        -- FHIR: HumanName.prefix (e.g., 'Dr.')
  first_name               VARCHAR(50),        -- FHIR: HumanName.given[0] -- name fo the contact person
  middle_name              VARCHAR(50),        -- FHIR: HumanName.given[1] (optional)
  last_name                VARCHAR(100),       -- FHIR: HumanName.family
  name_suffix              VARCHAR(50),        -- FHIR: HumanName.suffix (e.g., 'PhD')
  name_text                VARCHAR(200),       -- FHIR: HumanName.text (full display name)
  
  gender          VARCHAR(32), -- ('male','female','other','unknown')
  organization_id VARCHAR(64),
  period_start    DATE,
  period_end      DATE,
  
  patient_id      VARCHAR(64) NOT NULL,
  CONSTRAINT fk_contact_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
  CONSTRAINT fk_contact_org FOREIGN KEY (organization_id) REFERENCES insaights_organisation(id)
);

-- Patient Contact Relationship Table
CREATE TABLE insaights_contact_relationship ( --  same person can be employer and billing person
	id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),
    relationship_code      VARCHAR(32),
    
	contact_id  		   VARCHAR(64) NOT NULL,
    CONSTRAINT fk_crel_contact FOREIGN KEY (contact_id) REFERENCES insaights_contact(id)
);

-- Patient Contact Telecom Table
CREATE TABLE insaights_contact_telecom ( -- can have mutiple communication modes
    id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),
    
    `system`    VARCHAR(32), -- ('phone','fax','email','pager','url','sms','other'),
    `value`     VARCHAR(128), -- real value
    `use`       VARCHAR(32),  -- ('home','work','temp','old','mobile'),
    `rank`      INT UNSIGNED, -- which is of highest priority
    period_start DATE,
    period_end   DATE,
    
    contact_id  VARCHAR(64) NOT NULL,
    CONSTRAINT fk_ctelecom_contact FOREIGN KEY (contact_id) REFERENCES insaights_contact(id)
);

-- Patient Contact Address Table
CREATE TABLE insaights_contact_address ( -- can have multiple address,homes of contact person
	id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),
  
    `use`       VARCHAR(32),  -- ('home','work','temp','old','billing'),
    `type`      VARCHAR(32), -- ('postal','physical','both')
    `text`      TEXT,       -- real address like number(mb)
    line1       VARCHAR(128),
    line2       VARCHAR(128),
    city        VARCHAR(64),
    district    VARCHAR(64),
    state       VARCHAR(64),
    postal_code VARCHAR(20),
    country     VARCHAR(64),
    period_start DATE,
    period_end   DATE,
    
	contact_id  VARCHAR(64) NOT NULL UNIQUE,
    CONSTRAINT fk_caddr_contact FOREIGN KEY (contact_id) REFERENCES insaights_contact(id)
);

-- Patient Communication Table
CREATE TABLE insaights_communication ( -- a patient can prefer multiple languages which he may prefer
    id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),
    patient_id      VARCHAR(64) NOT NULL,
    language_code   VARCHAR(32) NOT NULL,
    preferred       BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_comm_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
);


-- Patient Link Table
CREATE TABLE insaights_patient_link (
    id VARCHAR(64) PRIMARY KEY DEFAULT (UUID()),
    other_patient_id  VARCHAR(64),                  -- optional: linked patient
    related_person_id VARCHAR(64),                  -- optional: linked related person
    
    `type`       VARCHAR(32) NOT NULL, -- 'replaced-by','replaces','refer','seealso'),
	patient_id        VARCHAR(64) NOT NULL, -- main patient linked
    
	CONSTRAINT    UNIQUE(patient_id, type),
    CONSTRAINT fk_link_patient          FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_link_other_patient    FOREIGN KEY (other_patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_link_related_person   FOREIGN KEY (related_person_id) REFERENCES insaights_related_person(id),
    
    CONSTRAINT CHECK (
		(other_patient_id IS NOT NULL AND related_person_id IS NULL)
		OR
		(other_patient_id IS NULL AND related_person_id IS NOT NULL)
	)
);