-- Part 1/3: core master tables, organisation, attachment, patient, practitioner
-- Run this first

-- enable pgcrypto (harmless if already exists)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) insaights_codeable_concept (master codes)
CREATE TABLE insaights_codeable_concept (
    concept_type VARCHAR(50) NOT NULL,
    code VARCHAR(32) NOT NULL,
    system VARCHAR(255),
    display VARCHAR(255),
    text VARCHAR(255),
    PRIMARY KEY (concept_type, code)
);
COMMENT ON TABLE insaights_codeable_concept IS $$its the Master Key contains codes$$;
COMMENT ON COLUMN insaights_codeable_concept.concept_type IS $$Defines the category of the concept (e.g., encounter status, act priority)$$;
COMMENT ON COLUMN insaights_codeable_concept.code IS $$Code value within the concept type (e.g., planned, in-progress)$$;
COMMENT ON COLUMN insaights_codeable_concept.system IS $$URI that defines the coding system (e.g., HL7 FHIR system URL)$$;
COMMENT ON COLUMN insaights_codeable_concept.display IS $$Human-readable display name for the code (e.g., Planned, In Progress)$$;
COMMENT ON COLUMN insaights_codeable_concept.text IS $$Optional free-text description provided by the user$$;

-- 2) insaights_organisation
CREATE TABLE insaights_organisation (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(128),
    address VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(100),
    active BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE insaights_organisation IS $$stores organisation detaila$$;
COMMENT ON COLUMN insaights_organisation.id IS $$Unique UUID identifier for the organisation$$;
COMMENT ON COLUMN insaights_organisation.name IS $$Legal name of the organisation (e.g., hospital, clinic)$$;
COMMENT ON COLUMN insaights_organisation.type IS $$Type or category of the organisation (e.g., hospital, clinic)$$;
COMMENT ON COLUMN insaights_organisation.address IS $$Primary address of the organisation$$;
COMMENT ON COLUMN insaights_organisation.phone IS $$Official contact phone number$$;
COMMENT ON COLUMN insaights_organisation.email IS $$General contact email address$$;
COMMENT ON COLUMN insaights_organisation.active IS $$TRUE if organisation is active; FALSE if inactive$$;

-- 3) insaights_attachment
CREATE TABLE insaights_attachment (
    id VARCHAR(64) PRIMARY KEY,
    content_type VARCHAR(64),
    content_language VARCHAR(32),
    url TEXT,
    content_data BYTEA,
    title VARCHAR(128),
    size INTEGER,
    content_hash BYTEA,
    creation_date TIMESTAMP
);
COMMENT ON TABLE insaights_attachment IS $$FHIR Attachment resource: used for storing patient photos, ABHA card scans, and other documents$$;
COMMENT ON COLUMN insaights_attachment.id IS $$Unique ID for attachment$$;
COMMENT ON COLUMN insaights_attachment.content_type IS $$MIME type of the file, e.g., image/jpeg or application/pdf$$;
COMMENT ON COLUMN insaights_attachment.content_language IS $$Language of the attachment content (FHIR Attachment.language)$$;
COMMENT ON COLUMN insaights_attachment.url IS $$External URL where the attachment is stored (if not in DB)$$;
COMMENT ON COLUMN insaights_attachment.content_data IS $$Inline binary data (e.g., ABHA card image, patient photo)$$;
COMMENT ON COLUMN insaights_attachment.title IS $$Human-readable title for the attachment$$;
COMMENT ON COLUMN insaights_attachment.size IS $$File size in bytes$$;
COMMENT ON COLUMN insaights_attachment.content_hash IS $$SHA-1 hash (20 bytes) for file integrity verification$$;
COMMENT ON COLUMN insaights_attachment.creation_date IS $$Timestamp when the attachment was created$$;

-- 4) insaights_patient
CREATE TABLE insaights_patient (
    id VARCHAR(64) PRIMARY KEY,

    name_prefix VARCHAR(50),
    first_name VARCHAR(50),
    middle_name VARCHAR(50),
    last_name VARCHAR(100),
    name_suffix VARCHAR(50),
    full_name VARCHAR(200),

    active BOOLEAN,
    gender VARCHAR(32),
    birth_date DATE,

    deceased_boolean BOOLEAN,
    deceased_datetime TIMESTAMP,

    marital_status_code VARCHAR(32),

    multiple_birth_boolean BOOLEAN,
    multiple_birth_integer INTEGER,

    photo VARCHAR(64),
    religion VARCHAR(32),
    annual_income INTEGER,
    nationality VARCHAR(32),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(64) NOT NULL,
    modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(64) NOT NULL DEFAULT 'SYSTEM',

    managing_organization_id VARCHAR(64),

    CONSTRAINT chk_deceased CHECK (
        (deceased_boolean = TRUE AND deceased_datetime IS NOT NULL) OR
        (deceased_boolean = FALSE AND deceased_datetime IS NULL)
    ),
    CONSTRAINT chk_mul_birth CHECK (
        (multiple_birth_boolean = TRUE AND multiple_birth_integer IS NOT NULL) OR
        (multiple_birth_boolean = FALSE AND multiple_birth_integer IS NULL)
    ),
    CONSTRAINT fk_patient_attachment FOREIGN KEY (photo) REFERENCES insaights_attachment(id),
    CONSTRAINT fk_patient_org FOREIGN KEY (managing_organization_id) REFERENCES insaights_organisation(id)
);
COMMENT ON TABLE insaights_patient IS $$Stores patient demographic and administrative data (FHIR: Patient resource)$$;
COMMENT ON COLUMN insaights_patient.id IS $$Unique identifier for the patient (FHIR resource id, UUID or similar)$$;
COMMENT ON COLUMN insaights_patient.name_prefix IS $$Name prefix (FHIR: HumanName.prefix), e.g., Dr., Mr., Ms.$$;
COMMENT ON COLUMN insaights_patient.first_name IS $$Given name / first name of the patient (FHIR: HumanName.given[0])$$;
COMMENT ON COLUMN insaights_patient.middle_name IS $$Middle name of the patient (FHIR: HumanName.given[1]), optional$$;
COMMENT ON COLUMN insaights_patient.last_name IS $$Family name / surname (FHIR: HumanName.family)$$;
COMMENT ON COLUMN insaights_patient.name_suffix IS $$Name suffix (FHIR: HumanName.suffix), e.g., PhD$$;
COMMENT ON COLUMN insaights_patient.full_name IS $$Full display name (FHIR: HumanName.text), concatenated or preferred display$$;
COMMENT ON COLUMN insaights_patient.active IS $$Indicates whether the patient record is active (FHIR: active)$$;
COMMENT ON COLUMN insaights_patient.gender IS $$Administrative gender of the patient (FHIR: gender), e.g., male, female, other$$;
COMMENT ON COLUMN insaights_patient.birth_date IS $$Date of birth of the patient (FHIR: birthDate)$$;
COMMENT ON COLUMN insaights_patient.deceased_boolean IS $$Indicates whether the patient is deceased (FHIR: deceasedBoolean)$$;
COMMENT ON COLUMN insaights_patient.deceased_datetime IS $$Date/time of death (FHIR: deceasedDateTime) if known$$;
COMMENT ON COLUMN insaights_patient.marital_status_code IS $$Marital status of the patient (FHIR: maritalStatus code)$$;
COMMENT ON COLUMN insaights_patient.multiple_birth_boolean IS $$Indicates whether patient is part of a multiple birth (FHIR: multipleBirthBoolean)$$;
COMMENT ON COLUMN insaights_patient.multiple_birth_integer IS $$Birth order in case of multiple birth (FHIR: multipleBirthInteger)$$;
COMMENT ON COLUMN insaights_patient.photo IS $$Reference to patient photo (FK to insaights_attachment)$$;
COMMENT ON COLUMN insaights_patient.religion IS $$Religion of the patient, used for hospital-specific purposes$$;
COMMENT ON COLUMN insaights_patient.annual_income IS $$Annual income of the patient, optional for administrative purposes$$;
COMMENT ON COLUMN insaights_patient.nationality IS $$Nationality of the patient$$;
COMMENT ON COLUMN insaights_patient.created_at IS $$Record creation timestamp$$;
COMMENT ON COLUMN insaights_patient.created_by IS $$Record created by (user id)$$;
COMMENT ON COLUMN insaights_patient.modified_at IS $$Record modification timestamp (note: Postgres requires trigger to auto-update on row changes)$$;
COMMENT ON COLUMN insaights_patient.modified_by IS $$Record modified by (user id)$$;
COMMENT ON COLUMN insaights_patient.managing_organization_id IS $$FK to organization that manages the patient record (FHIR: managingOrganization)$$;

-- 5) insaights_practitioner
CREATE TABLE insaights_practitioner (
    id VARCHAR(64) PRIMARY KEY,
    given_name VARCHAR(100),
    family_name VARCHAR(100),
    gender VARCHAR(32),
    birth_date TIMESTAMP,
    phone VARCHAR(50),
    email VARCHAR(100),
    active BOOLEAN DEFAULT TRUE
);
COMMENT ON TABLE insaights_practitioner IS $$Healthcare professional who provides direct services to patients$$;
COMMENT ON COLUMN insaights_practitioner.id IS $$Unique UUID identifier for the practitioner$$;
COMMENT ON COLUMN insaights_practitioner.given_name IS $$Practitioner’s given/first name$$;
COMMENT ON COLUMN insaights_practitioner.family_name IS $$Practitioner’s family/last name$$;
COMMENT ON COLUMN insaights_practitioner.gender IS $$Gender identity of the practitioner (e.g., male, female, other)$$;
COMMENT ON COLUMN insaights_practitioner.birth_date IS $$Date of birth of the practitioner$$;
COMMENT ON COLUMN insaights_practitioner.phone IS $$Contact phone number of the practitioner$$;
COMMENT ON COLUMN insaights_practitioner.email IS $$Official or professional email address$$;
COMMENT ON COLUMN insaights_practitioner.active IS $$TRUE if the practitioner is currently active; FALSE otherwise$$;

-- Part 2/3: practitioner_role, general_practitioner, related_person, identifier, telecom, address
-- Run this after Part 1

-- 6) insaights_practitioner_role
CREATE TABLE insaights_practitioner_role (
    id VARCHAR(64) PRIMARY KEY,
    practitioner_id VARCHAR(64),
    organization_id VARCHAR(64),
    role VARCHAR(100),
    specialty VARCHAR(100),
    contact_number VARCHAR(50),
    email VARCHAR(100),
    available_start TIMESTAMP,
    available_end TIMESTAMP,
    active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    CONSTRAINT fk_practitioner_role_practitioner FOREIGN KEY (practitioner_id) REFERENCES insaights_practitioner(id),
    CONSTRAINT fk_practitioner_role_org FOREIGN KEY (organization_id) REFERENCES insaights_organisation(id)
);
COMMENT ON TABLE insaights_practitioner_role IS $$Stores roles and responsibilities of healthcare practitioners within organizations$$;
COMMENT ON COLUMN insaights_practitioner_role.id IS $$Unique identifier for the practitioner role$$;
COMMENT ON COLUMN insaights_practitioner_role.practitioner_id IS $$Reference to Practitioner$$;
COMMENT ON COLUMN insaights_practitioner_role.organization_id IS $$Reference to Organization$$;
COMMENT ON COLUMN insaights_practitioner_role.role IS $$Role of the practitioner, e.g., Doctor, Nurse, Surgeon$$;
COMMENT ON COLUMN insaights_practitioner_role.specialty IS $$Specialty of the practitioner, e.g., Cardiology, Pediatrics$$;
COMMENT ON COLUMN insaights_practitioner_role.contact_number IS $$Phone or mobile number$$;
COMMENT ON COLUMN insaights_practitioner_role.email IS $$Email address of the practitioner role$$;
COMMENT ON COLUMN insaights_practitioner_role.available_start IS $$Start of availability period$$;
COMMENT ON COLUMN insaights_practitioner_role.available_end IS $$End of availability period$$;
COMMENT ON COLUMN insaights_practitioner_role.active IS $$Whether the role is currently active$$;
COMMENT ON COLUMN insaights_practitioner_role.notes IS $$Additional notes or description$$;

-- 7) insaights_general_practitioner
CREATE TABLE insaights_general_practitioner (
    id VARCHAR(64) PRIMARY KEY,
    organisation_id VARCHAR(64),
    practitioner_id VARCHAR(64),
    practitioner_role_id VARCHAR(64),
    patient_id VARCHAR(64) NOT NULL,
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
COMMENT ON TABLE insaights_general_practitioner IS $$Temporary table for referencing general practitioners to patients; allows only one type of reference (practitioner, organization, or role)$$;
COMMENT ON COLUMN insaights_general_practitioner.id IS $$Unique ID; used for referencing multiple practitioner types$$;
COMMENT ON COLUMN insaights_general_practitioner.organisation_id IS $$Reference to Organisation (if applicable)$$;
COMMENT ON COLUMN insaights_general_practitioner.practitioner_id IS $$Reference to Practitioner (if applicable)$$;
COMMENT ON COLUMN insaights_general_practitioner.practitioner_role_id IS $$Reference to Practitioner Role (if applicable)$$;
COMMENT ON COLUMN insaights_general_practitioner.patient_id IS $$Reference to Patient$$;

-- 8) insaights_related_person
CREATE TABLE insaights_related_person (
    id VARCHAR(64) PRIMARY KEY,
    patient_id VARCHAR(64) NOT NULL,
    name_text VARCHAR(128),
    relationship_code VARCHAR(64),
    gender VARCHAR(32),
    birth_date DATE,
    telecom VARCHAR(128),
    address TEXT,
    active BOOLEAN DEFAULT TRUE,
    period_start TIMESTAMP,
    period_end TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_related_person_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
);
COMMENT ON TABLE insaights_related_person IS $$Represents a person involved in a patient’s care, such as a caregiver or family member$$;
COMMENT ON COLUMN insaights_related_person.id IS $$Unique FHIR resource ID for related person$$;
COMMENT ON COLUMN insaights_related_person.patient_id IS $$Reference to the patient$$;
COMMENT ON COLUMN insaights_related_person.name_text IS $$Full name of the related person$$;
COMMENT ON COLUMN insaights_related_person.relationship_code IS $$Type of relationship to the patient (e.g., mother, spouse)$$;
COMMENT ON COLUMN insaights_related_person.gender IS $$Gender of the related person (male, female, other, unknown)$$;
COMMENT ON COLUMN insaights_related_person.birth_date IS $$Date of birth of the related person$$;
COMMENT ON COLUMN insaights_related_person.telecom IS $$Phone number or email contact$$;
COMMENT ON COLUMN insaights_related_person.address IS $$Home or mailing address$$;
COMMENT ON COLUMN insaights_related_person.active IS $$Indicates if the record is currently active$$;
COMMENT ON COLUMN insaights_related_person.period_start IS $$Start date of this relationship being valid$$;
COMMENT ON COLUMN insaights_related_person.period_end IS $$End date of this relationship being valid$$;
COMMENT ON COLUMN insaights_related_person.created_at IS $$Timestamp when record was created$$;

-- 9) insaights_identifier
CREATE TABLE insaights_identifier (
    id VARCHAR(64) PRIMARY KEY,
    use_code VARCHAR(32),
    type_code VARCHAR(32),
    system VARCHAR(128),
    value VARCHAR(128),
    period_start TIMESTAMP,
    period_end TIMESTAMP,
    photo_attachment_id VARCHAR(64),
    assigner_id VARCHAR(64),
    patient_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_identifier_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_patient_identifier_attachment FOREIGN KEY (photo_attachment_id) REFERENCES insaights_attachment(id),
    CONSTRAINT fk_patient_identifier_assigner FOREIGN KEY (assigner_id) REFERENCES insaights_organisation(id)
);
COMMENT ON TABLE insaights_identifier IS $$FHIR Identifier table — stores patient identifiers such as MRN, SSN, passport, etc.$$;
COMMENT ON COLUMN insaights_identifier.id IS $$Unique identifier row ID (UUID)$$;
COMMENT ON COLUMN insaights_identifier.use_code IS $$Identifier use (official, usual, secondary, temp)$$;
COMMENT ON COLUMN insaights_identifier.type_code IS $$Identifier type code (e.g., driver license, passport, medical record number)$$;
COMMENT ON COLUMN insaights_identifier.system IS $$Namespace or issuing system (URI, OID, or URL of organization)$$;
COMMENT ON COLUMN insaights_identifier.value IS $$Actual identifier value$$;
COMMENT ON COLUMN insaights_identifier.period_start IS $$Validity start date of identifier$$;
COMMENT ON COLUMN insaights_identifier.period_end IS $$Validity end/expiry date of identifier$$;
COMMENT ON COLUMN insaights_identifier.photo_attachment_id IS $$FK → Attachment(id), optional photo associated with identifier$$;
COMMENT ON COLUMN insaights_identifier.assigner_id IS $$FK → Organization(id), who issued/assigns the identifier$$;
COMMENT ON COLUMN insaights_identifier.patient_id IS $$FK → Patient(id)$$;

-- 10) insaights_telecom
CREATE TABLE insaights_telecom (
    id VARCHAR(64) PRIMARY KEY,
    system VARCHAR(32),
    value VARCHAR(100),
    use VARCHAR(32),
    rank INTEGER,
    period_start TIMESTAMP,
    period_end TIMESTAMP,
    patient_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_telecom_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
);
COMMENT ON TABLE insaights_telecom IS $$Telecom details (phone, email, etc.) for a patient$$;
COMMENT ON COLUMN insaights_telecom.id IS $$Unique identifier for each telecom record$$;
COMMENT ON COLUMN insaights_telecom.system IS $$Type of contact system (e.g., phone, email, fax, url)$$;
COMMENT ON COLUMN insaights_telecom.value IS $$The actual contact detail (phone number, email address, etc.)$$;
COMMENT ON COLUMN insaights_telecom.use IS $$Purpose of contact (e.g., home, work, mobile, temp, old)$$;
COMMENT ON COLUMN insaights_telecom.rank IS $$Order of priority, lower number = higher priority (originally INT UNSIGNED in MySQL)$$;
COMMENT ON COLUMN insaights_telecom.period_start IS $$Date and time when this contact detail became valid$$;
COMMENT ON COLUMN insaights_telecom.period_end IS $$Date and time when this contact detail stopped being valid (NULL = still active)$$;
COMMENT ON COLUMN insaights_telecom.patient_id IS $$FK → Patient(id), owner of this telecom detail$$;

-- 11) insaights_address
CREATE TABLE insaights_address (
    id VARCHAR(64) PRIMARY KEY,
    use VARCHAR(32),
    type VARCHAR(32),
    text VARCHAR(200),
    line1 VARCHAR(128),
    line2 VARCHAR(128),
    line3 VARCHAR(128),
    line4 VARCHAR(128),
    city VARCHAR(64),
    district VARCHAR(64),
    state VARCHAR(64),
    postal_code VARCHAR(20),
    country VARCHAR(64),
    period_start TIMESTAMP,
    period_end TIMESTAMP,
    patient_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_address_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
);
COMMENT ON TABLE insaights_address IS $$Patient address details (FHIR: Patient.address), supports multiple addresses per patient for different uses and periods$$;
COMMENT ON COLUMN insaights_address.id IS $$Unique identifier for this address entry (FHIR: Address.id)$$;
COMMENT ON COLUMN insaights_address.use IS $$The purpose of this address (e.g., home, work, temporary, old, billing) (FHIR: Address.use)$$;
COMMENT ON COLUMN insaights_address.type IS $$Type of address: postal, physical, or both (FHIR: Address.type)$$;
COMMENT ON COLUMN insaights_address.text IS $$Human-readable full address representation (FHIR: Address.text)$$;
COMMENT ON COLUMN insaights_address.line1 IS $$Address line 1 (FHIR: Address.line[0])$$;
COMMENT ON COLUMN insaights_address.line2 IS $$Address line 2 (FHIR: Address.line[1])$$;
COMMENT ON COLUMN insaights_address.line3 IS $$Address line 3 (FHIR: Address.line[2])$$;
COMMENT ON COLUMN insaights_address.line4 IS $$Address line 4 (FHIR: Address.line[3])$$;
COMMENT ON COLUMN insaights_address.city IS $$City or locality (FHIR: Address.city)$$;
COMMENT ON COLUMN insaights_address.district IS $$District or county (FHIR: Address.district)$$;
COMMENT ON COLUMN insaights_address.state IS $$State, province, or region (FHIR: Address.state)$$;
COMMENT ON COLUMN insaights_address.postal_code IS $$Postal or ZIP code (FHIR: Address.postalCode)$$;
COMMENT ON COLUMN insaights_address.country IS $$Country name (FHIR: Address.country)$$;
COMMENT ON COLUMN insaights_address.period_start IS $$Start date for which this address is valid (FHIR: Address.period.start)$$;
COMMENT ON COLUMN insaights_address.period_end IS $$End date for which this address is valid (FHIR: Address.period.end)$$;
COMMENT ON COLUMN insaights_address.patient_id IS $$FK to patient who owns this address (FHIR: Reference(Patient))$$;

-- Part 3/3: contact, contact relationships, contact telecom, communication, patient link
-- Run this last

-- 12) insaights_contact
CREATE TABLE insaights_contact (
    id VARCHAR(64) PRIMARY KEY,

    name_prefix VARCHAR(50),
    first_name VARCHAR(50),
    middle_name VARCHAR(50),
    last_name VARCHAR(100),
    name_suffix VARCHAR(50),
    name_text VARCHAR(200),

    address_use VARCHAR(32),
    address_type VARCHAR(32),
    address_text VARCHAR(200),

    address_line1 VARCHAR(128),
    address_line2 VARCHAR(128),
    address_line3 VARCHAR(128),
    address_line4 VARCHAR(128),

    address_city VARCHAR(64),
    address_district VARCHAR(64),
    address_state VARCHAR(64),
    address_postal_code VARCHAR(20),
    adress_country VARCHAR(64),

    address_period_start TIMESTAMP,
    address_period_end TIMESTAMP,

    gender VARCHAR(32),
    organization_id VARCHAR(64),
    period_start TIMESTAMP,
    period_end TIMESTAMP,

    patient_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_contact_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_contact_org FOREIGN KEY (organization_id) REFERENCES insaights_organisation(id)
);
COMMENT ON TABLE insaights_contact IS $$FHIR Patient.contact: Represents one or more contacts for a patient, such as next-of-kin or emergency contacts, including names, gender, organization, and period of validity$$;
COMMENT ON COLUMN insaights_contact.id IS $$Unique identifier for this contact entry (UUID or FHIR id)$$;
COMMENT ON COLUMN insaights_contact.name_prefix IS $$FHIR: HumanName.prefix (e.g., Dr.)$$;
COMMENT ON COLUMN insaights_contact.first_name IS $$FHIR: HumanName.given[0] -- first/given name of contact$$;
COMMENT ON COLUMN insaights_contact.middle_name IS $$FHIR: HumanName.given[1] -- optional middle name$$;
COMMENT ON COLUMN insaights_contact.last_name IS $$FHIR: HumanName.family -- family/last name of contact$$;
COMMENT ON COLUMN insaights_contact.name_suffix IS $$FHIR: HumanName.suffix (e.g., PhD)$$;
COMMENT ON COLUMN insaights_contact.name_text IS $$FHIR: HumanName.text -- full display name$$;
COMMENT ON COLUMN insaights_contact.address_use IS $$The purpose of this address (e.g., home, work, temporary, old, billing) (FHIR: Address.use)$$;
COMMENT ON COLUMN insaights_contact.address_type IS $$Type of address: postal, physical, or both (FHIR: Address.type)$$;
COMMENT ON COLUMN insaights_contact.address_text IS $$Human-readable full address representation (FHIR: Address.text)$$;
COMMENT ON COLUMN insaights_contact.address_line1 IS $$Address line 1 (FHIR: Address.line[0])$$;
COMMENT ON COLUMN insaights_contact.address_line2 IS $$Address line 2 (FHIR: Address.line[1])$$;
COMMENT ON COLUMN insaights_contact.address_line3 IS $$Address line 3 (FHIR: Address.line[2])$$;
COMMENT ON COLUMN insaights_contact.address_line4 IS $$Address line 4 (FHIR: Address.line[3])$$;
COMMENT ON COLUMN insaights_contact.address_city IS $$City or locality (FHIR: Address.city)$$;
COMMENT ON COLUMN insaights_contact.address_district IS $$District or county (FHIR: Address.district)$$;
COMMENT ON COLUMN insaights_contact.address_state IS $$State, province, or region (FHIR: Address.state)$$;
COMMENT ON COLUMN insaights_contact.address_postal_code IS $$Postal or ZIP code (FHIR: Address.postalCode)$$;
COMMENT ON COLUMN insaights_contact.adress_country IS $$Country name (FHIR: Address.country)$$;
COMMENT ON COLUMN insaights_contact.address_period_start IS $$Start date for which this address is valid (FHIR: Address.period.start)$$;
COMMENT ON COLUMN insaights_contact.address_period_end IS $$End date for which this address is valid (FHIR: Address.period.end)$$;
COMMENT ON COLUMN insaights_contact.gender IS $$Administrative gender of the contact (male, female, other, unknown)$$;
COMMENT ON COLUMN insaights_contact.organization_id IS $$FK to Organization -- affiliation of the contact person$$;
COMMENT ON COLUMN insaights_contact.period_start IS $$Start of validity period for this contact (FHIR: Period.start)$$;
COMMENT ON COLUMN insaights_contact.period_end IS $$End of validity period for this contact (FHIR: Period.end)$$;
COMMENT ON COLUMN insaights_contact.patient_id IS $$FK to Patient -- patient this contact is associated with$$;

-- 13) insaights_contact_relationship
CREATE TABLE insaights_contact_relationship (
    id VARCHAR(64) PRIMARY KEY,
    relationship_code VARCHAR(32),
    contact_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_crel_contact FOREIGN KEY (contact_id) REFERENCES insaights_contact(id)
);
COMMENT ON TABLE insaights_contact_relationship IS $$FHIR Patient.contact.relationship: Represents multiple roles or relationships a contact can have with the patient, allowing one contact to have multiple relationship codes$$;
COMMENT ON COLUMN insaights_contact_relationship.id IS $$Unique identifier for this contact-relationship entry (UUID or FHIR id)$$;
COMMENT ON COLUMN insaights_contact_relationship.relationship_code IS $$Code indicating the relationship type (e.g., next-of-kin, employer, billing, emergency contact)$$;
COMMENT ON COLUMN insaights_contact_relationship.contact_id IS $$FK to Contact -- the contact to whom this relationship applies$$;

-- 14) insaights_contact_telecom
CREATE TABLE insaights_contact_telecom (
    id VARCHAR(64) PRIMARY KEY,
    system VARCHAR(32),
    value VARCHAR(128),
    use VARCHAR(32),
    rank INTEGER,
    period_start TIMESTAMP,
    period_end TIMESTAMP,
    contact_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_ctelecom_contact FOREIGN KEY (contact_id) REFERENCES insaights_contact(id)
);
COMMENT ON TABLE insaights_contact_telecom IS $$FHIR Patient.contact.telecom: Stores multiple communication points for a contact person, allowing different systems, usage, and priority$$;
COMMENT ON COLUMN insaights_contact_telecom.id IS $$Unique identifier for this telecom entry (UUID or FHIR id)$$;
COMMENT ON COLUMN insaights_contact_telecom.system IS $$Telecom system type (e.g., phone, fax, email, pager, url, sms, other)$$;
COMMENT ON COLUMN insaights_contact_telecom.value IS $$Actual contact value (e.g., phone number, email address, URL)$$;
COMMENT ON COLUMN insaights_contact_telecom.use IS $$Usage type (e.g., home, work, temp, old, mobile)$$;
COMMENT ON COLUMN insaights_contact_telecom.rank IS $$Priority of this contact point; lower number = higher priority (originally INT UNSIGNED in MySQL)$$;
COMMENT ON COLUMN insaights_contact_telecom.period_start IS $$Start date when this contact point is valid/active$$;
COMMENT ON COLUMN insaights_contact_telecom.period_end IS $$End date when this contact point is valid/active$$;
COMMENT ON COLUMN insaights_contact_telecom.contact_id IS $$FK to Contact -- the contact this telecom belongs to$$;

-- 15) insaights_communication
CREATE TABLE insaights_communication (
    id VARCHAR(64) PRIMARY KEY,
    patient_id VARCHAR(64) NOT NULL,
    language_code VARCHAR(32) NOT NULL,
    preferred BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_comm_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
);
COMMENT ON TABLE insaights_communication IS $$Patient communication preferences, preferred languages$$;
COMMENT ON COLUMN insaights_communication.id IS $$Unique identifier for this communication entry (UUID or FHIR id)$$;
COMMENT ON COLUMN insaights_communication.patient_id IS $$FK to Patient; identifies the patient this communication preference belongs to$$;
COMMENT ON COLUMN insaights_communication.language_code IS $$Code representing the language (e.g., en, hi, fr)$$;
COMMENT ON COLUMN insaights_communication.preferred IS $$Indicates if this is the patient’s preferred language (TRUE/FALSE)$$;

-- 16) insaights_patient_link
CREATE TABLE insaights_patient_link (
    id VARCHAR(64) PRIMARY KEY,
    other_patient_id VARCHAR(64),
    related_person_id VARCHAR(64),
    type VARCHAR(32) NOT NULL,
    patient_id VARCHAR(64) NOT NULL,
    CONSTRAINT unique_patient_type UNIQUE (patient_id, type),
    CONSTRAINT fk_link_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_link_other_patient FOREIGN KEY (other_patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_link_related_person FOREIGN KEY (related_person_id) REFERENCES insaights_related_person(id),
    CONSTRAINT chk_link CHECK (
        (other_patient_id IS NOT NULL AND related_person_id IS NULL) OR
        (other_patient_id IS NULL AND related_person_id IS NOT NULL)
    )
);
COMMENT ON TABLE insaights_patient_link IS $$helps in duplcate check and updates$$;
COMMENT ON COLUMN insaights_patient_link.id IS $$Unique identifier for this patient link entry (UUID or FHIR id)$$;
COMMENT ON COLUMN insaights_patient_link.other_patient_id IS $$FK to another Patient; represents a linked patient (optional)$$;
COMMENT ON COLUMN insaights_patient_link.related_person_id IS $$FK to a RelatedPerson; represents a linked related person (optional)$$;
COMMENT ON COLUMN insaights_patient_link.type IS $$Type of link (e.g., replaced-by, replaces, refer, seealso)$$;
COMMENT ON COLUMN insaights_patient_link.patient_id IS $$FK to the main Patient to whom this link belongs$$;
