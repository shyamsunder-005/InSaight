-- Patient Resource with 16 tables
-- Demographics and other administrative information about an individual or animal receiving care or other health-related services.

CREATE TABLE insaights_codeable_concept ( -- Lookup table for centralised/decentralised codeable concepts
    concept_type VARCHAR(50) NOT NULL COMMENT 'Defines the category of the concept (e.g., encounter status, act priority)',
    `code` VARCHAR(32) NOT NULL COMMENT 'Code value within the concept type (e.g., planned, in-progress)',
    `system` VARCHAR(255) COMMENT 'URI that defines the coding system (e.g., HL7 FHIR system URL)',
    display VARCHAR(255) COMMENT 'Human-readable display name for the code (e.g., Planned, In Progress)',
    `text` VARCHAR(255) COMMENT 'Optional free-text description provided by the user',
    PRIMARY KEY (concept_type, code) -- Composite primary key for uniqueness within each concept type
) COMMENT = 'its the Master Key contains codes';


CREATE TABLE insaights_organisation ( -- hospitals, clinics #TEMPORARY TABLES
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique UUID identifier for the organisation',
    
    `name` VARCHAR(255) NOT NULL COMMENT 'Legal name of the organisation (e.g., hospital, clinic)',
    `type` VARCHAR(128) COMMENT 'Type or category of the organisation (e.g., hospital, clinic)',
    address VARCHAR(255) COMMENT 'Primary address of the organisation',
    phone VARCHAR(50) COMMENT 'Official contact phone number',
    email VARCHAR(100) COMMENT 'General contact email address',
    `active` BOOLEAN DEFAULT TRUE COMMENT 'TRUE if organisation is active; FALSE if inactive'
)COMMENT = 'stores organisation detaila';

CREATE TABLE insaights_attachment ( -- --  attachment where abha card will be saved 
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique ID for attachment',
    content_type    		VARCHAR(64) COMMENT 'MIME type of the file, e.g., image/jpeg or application/pdf',
    content_language      	VARCHAR(32) COMMENT 'Language of the attachment content (FHIR Attachment.language)',
    url             		TEXT COMMENT 'External URL where the attachment is stored (if not in DB)',
    content_data          	MEDIUMBLOB COMMENT 'Inline binary data (e.g., ABHA card image, patient photo)',
    title           		VARCHAR(128) COMMENT 'Human-readable title for the attachment',
    size            		INT COMMENT 'File size in bytes',
    content_hash          	VARBINARY(20) COMMENT 'SHA-1 hash (20 bytes) for file integrity verification',
    creation_date   		DATETIME COMMENT 'Timestamp when the attachment was created'
) COMMENT='FHIR Attachment resource: used for storing patient photos, ABHA card scans, and other documents';

CREATE TABLE insaights_patient ( -- FHIR Patient resource representation
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for the patient (FHIR resource id, UUID or similar)',
    
    name_prefix              VARCHAR(50) COMMENT 'Name prefix (FHIR: HumanName.prefix), e.g., Dr., Mr., Ms.',
    first_name               VARCHAR(50) COMMENT 'Given name / first name of the patient (FHIR: HumanName.given[0])',
    middle_name              VARCHAR(50) COMMENT 'Middle name of the patient (FHIR: HumanName.given[1]), optional',
    last_name                VARCHAR(100) COMMENT 'Family name / surname (FHIR: HumanName.family)',
    name_suffix              VARCHAR(50) COMMENT 'Name suffix (FHIR: HumanName.suffix), e.g., PhD',
    full_name                VARCHAR(200) COMMENT 'Full display name (FHIR: HumanName.text), concatenated or preferred display',

    `active`                 BOOLEAN COMMENT 'Indicates whether the patient record is active (FHIR: active)',

    gender                   VARCHAR(32) COMMENT 'Administrative gender of the patient (FHIR: gender), e.g., male, female, other',
    birth_date               DATE COMMENT 'Date of birth of the patient (FHIR: birthDate)',

    deceased_boolean         BOOLEAN COMMENT 'Indicates whether the patient is deceased (FHIR: deceasedBoolean)',
    deceased_dateTime        DATETIME COMMENT 'Date/time of death (FHIR: deceasedDateTime) if known',

    marital_status_code      VARCHAR(32) COMMENT 'Marital status of the patient (FHIR: maritalStatus code)',

    multiple_birth_boolean   BOOLEAN COMMENT 'Indicates whether patient is part of a multiple birth (FHIR: multipleBirthBoolean)',
    multiple_birth_integer   INT COMMENT 'Birth order in case of multiple birth (FHIR: multipleBirthInteger)',

    photo                    VARCHAR(64) COMMENT 'Reference to patient photo (FK to insaights_attachment)',
    religion                 VARCHAR(32) COMMENT 'Religion of the patient, used for hospital-specific purposes',
    annual_income            INT COMMENT 'Annual income of the patient, optional for administrative purposes',
    nationality              VARCHAR(32) COMMENT 'Nationality of the patient',

	created_at 				TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by 				VARCHAR(64) NOT NULL,
    modified_at 			TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	modified_by 			VARCHAR(64) NOT NULL DEFAULT 'SYSTEM',

    managing_organization_id VARCHAR(64) COMMENT 'FK to organization that manages the patient record (FHIR: managingOrganization)',
    
	CONSTRAINT chk_deceased
		CHECK (
		(deceased_boolean = TRUE AND deceased_dateTime IS NOT NULL) OR
		(deceased_boolean = FALSE AND deceased_dateTime IS NULL) 
	),
    
	CONSTRAINT chk_mul_birth
		CHECK (
		(multiple_birth_boolean = TRUE AND multiple_birth_integer IS NOT NULL) OR
		(multiple_birth_boolean = FALSE AND multiple_birth_integer IS NULL)
	),

    CONSTRAINT fk_patient_attachment FOREIGN KEY (photo) REFERENCES insaights_attachment(id),
    CONSTRAINT fk_patient_org        FOREIGN KEY (managing_organization_id) REFERENCES insaights_organisation(id)
) COMMENT = 'Stores patient demographic and administrative data (FHIR: Patient resource)';

CREATE TABLE insaights_practitioner ( -- Healthcare professional who provides direct services to patients
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique UUID identifier for the practitioner',
    
    given_name 				VARCHAR(100) COMMENT 'Practitioner’s given/first name',
    family_name 			VARCHAR(100) COMMENT 'Practitioner’s family/last name',
    gender 					VARCHAR(32) COMMENT 'Gender identity of the practitioner (e.g., male, female, other)',
    birth_date 				DATETIME COMMENT 'Date of birth of the practitioner',
    phone 					VARCHAR(50) COMMENT 'Contact phone number of the practitioner',
    email 					VARCHAR(100) COMMENT 'Official or professional email address',
    `active` 				BOOLEAN DEFAULT TRUE COMMENT 'TRUE if the practitioner is currently active; FALSE otherwise'
);

CREATE TABLE insaights_practitioner_role (
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for the practitioner role',
    
    practitioner_id 		VARCHAR(64) COMMENT 'Reference to Practitioner',
    organization_id 		VARCHAR(64) COMMENT 'Reference to Organization',
    `role` 					VARCHAR(100) COMMENT 'Role of the practitioner, e.g., Doctor, Nurse, Surgeon',
    specialty 				VARCHAR(100) COMMENT 'Specialty of the practitioner, e.g., Cardiology, Pediatrics',
    contact_number 			VARCHAR(50) COMMENT 'Phone or mobile number',
    email 					VARCHAR(100) COMMENT 'Email address of the practitioner',
    available_start 		DATETIME COMMENT 'Start of availability period',
    available_end 			DATETIME COMMENT 'End of availability period',
    `active` 				BOOLEAN DEFAULT TRUE COMMENT 'Whether the role is currently active',
    notes 					TEXT COMMENT 'Additional notes or description'
) COMMENT = 'Stores roles and responsibilities of healthcare practitioners within organizations';

CREATE TABLE insaights_general_practitioner (
    id VARCHAR(64) PRIMARY KEY  COMMENT 'Unique ID; used for referencing multiple practitioner types',
    
    organisation_id 		VARCHAR(64) COMMENT 'Reference to Organisation (if applicable)',
    practitioner_id 		VARCHAR(64) COMMENT 'Reference to Practitioner (if applicable)',
    practitioner_role_id 	VARCHAR(64) COMMENT 'Reference to Practitioner Role (if applicable)',
    patient_id 				VARCHAR(64) NOT NULL COMMENT 'Reference to Patient',

    CONSTRAINT fk_prac_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_org_patient FOREIGN KEY (organisation_id) REFERENCES insaights_organisation(id),
    CONSTRAINT fk_org_patient_role FOREIGN KEY (practitioner_role_id) REFERENCES insaights_practitioner_role(id),
    CONSTRAINT fk_practitioner FOREIGN KEY (practitioner_id) REFERENCES insaights_practitioner(id),

    CONSTRAINT chk_only_one_reference CHECK (
        (practitioner_id IS NOT NULL AND organisation_id IS NULL AND practitioner_role_id IS NULL) OR
        (practitioner_id IS NULL AND organisation_id IS NOT NULL AND practitioner_role_id IS NULL) OR
        (practitioner_id IS NULL AND organisation_id IS NULL AND practitioner_role_id IS NOT NULL)
    )
) COMMENT='Temporary table for referencing general practitioners to patients; allows only one type of reference (practitioner, organization, or role)';

CREATE TABLE insaights_related_person (
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique FHIR resource ID for related person',
    
    patient_id 				VARCHAR(64) NOT NULL COMMENT 'Reference to the patient',
    name_text 				VARCHAR(128) COMMENT 'Full name of the related person',
    relationship_code 		VARCHAR(64) COMMENT 'Type of relationship to the patient (e.g., mother, spouse)',
    gender 					VARCHAR(32) COMMENT 'Gender of the related person (male, female, other, unknown)',
    birth_date 				DATE COMMENT 'Date of birth of the related person',
    telecom 				VARCHAR(128) COMMENT 'Phone number or email contact',
    address 				TEXT COMMENT 'Home or mailing address',
    `active` 				BOOLEAN DEFAULT TRUE COMMENT 'Indicates if the record is currently active',
    period_start 			DATETIME COMMENT 'Start date of this relationship being valid',
    period_end 				DATETIME COMMENT 'End date of this relationship being valid',
    created_at 				DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when record was created',

    CONSTRAINT fk_related_person_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)

) COMMENT = 'Represents a person involved in a patient’s care, such as a caregiver or family member';

-- Patient Identifier Table
CREATE TABLE insaights_identifier (
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier row ID (UUID)',

    use_code 				VARCHAR(32) COMMENT 'Identifier use (official, usual, secondary, temp)',
    type_code 				VARCHAR(32) COMMENT 'Identifier type code (e.g., driver license, passport, medical record number)',
    `system` 				VARCHAR(128) COMMENT 'Namespace or issuing system (URI, OID, or URL of organization)',
    `value` 				VARCHAR(128) COMMENT 'Actual identifier value',
    period_start 			DATETIME COMMENT 'Validity start date of identifier',
    period_end 				DATETIME COMMENT 'Validity end/expiry date of identifier',

    photo_attachment_id 	VARCHAR(64) COMMENT 'FK → Attachment(id), optional photo associated with identifier',
    assigner_id 			VARCHAR(64) COMMENT 'FK → Organization(id), who issued/assigns the identifier',

    patient_id 				VARCHAR(64) NOT NULL COMMENT 'FK → Patient(id)',

    CONSTRAINT fk_identifier_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_patient_identifier_attachment FOREIGN KEY (photo_attachment_id) REFERENCES insaights_attachment(id),
    CONSTRAINT fk_patient_identifier_assigner FOREIGN KEY (assigner_id) REFERENCES insaights_organisation(id)
) COMMENT='FHIR Identifier table — stores patient identifiers such as MRN, SSN, passport, etc.';

-- A contact detail (telecom) for the individual patient
CREATE TABLE insaights_telecom (
  id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for each telecom record',
  
  `system`    			VARCHAR(32) COMMENT 'Type of contact system (e.g., phone, email, fax, url)',
  `value`     			VARCHAR(100) COMMENT 'The actual contact detail (phone number, email address, etc.)',
  `use`       			VARCHAR(32) COMMENT 'Purpose of contact (e.g., home, work, mobile, temp, old)',
  `rank`      			INT UNSIGNED COMMENT 'Order of priority, lower number = higher priority',
  
  period_start 			DATETIME COMMENT 'Date and time when this contact detail became valid',
  period_end   			DATETIME COMMENT 'Date and time when this contact detail stopped being valid (NULL = still active)',
  
  patient_id   			VARCHAR(64) NOT NULL COMMENT 'FK → Patient(id), owner of this telecom detail',
  
  CONSTRAINT fk_telecom_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
) COMMENT='Telecom details (phone, email, etc.) for a patient';

-- Patient Address Table
CREATE TABLE insaights_address (
  id VARCHAR(64) PRIMARY KEY  COMMENT 'Unique identifier for this address entry (FHIR: Address.id)',
  
  `use` 			VARCHAR(32) COMMENT 'The purpose of this address (e.g., home, work, temporary, old, billing) (FHIR: Address.use)',
  `type` 			VARCHAR(32) COMMENT 'Type of address: postal, physical, or both (FHIR: Address.type)',
  `text` 			VARCHAR(200) COMMENT 'Human-readable full address representation (FHIR: Address.text)',
  
  line1 			VARCHAR(128) COMMENT 'Address line 1 (FHIR: Address.line[0])',
  line2 			VARCHAR(128) COMMENT 'Address line 2 (FHIR: Address.line[1])',
  line3 			VARCHAR(128) COMMENT 'Address line 3 (FHIR: Address.line[2])',
  line4 			VARCHAR(128) COMMENT 'Address line 4 (FHIR: Address.line[3])',
  
  city 				VARCHAR(64) COMMENT 'City or locality (FHIR: Address.city)',
  district 			VARCHAR(64) COMMENT 'District or county (FHIR: Address.district)',
  state 			VARCHAR(64) COMMENT 'State, province, or region (FHIR: Address.state)',
  postal_code 		VARCHAR(20) COMMENT 'Postal or ZIP code (FHIR: Address.postalCode)',
  country 			VARCHAR(64) COMMENT 'Country name (FHIR: Address.country)',
  
  period_start 		DATETIME COMMENT 'Start date for which this address is valid (FHIR: Address.period.start)',
  period_end 		DATETIME COMMENT 'End date for which this address is valid (FHIR: Address.period.end)',
  
  patient_id 		VARCHAR(64) NOT NULL COMMENT 'FK to patient who owns this address (FHIR: Reference(Patient))',
  CONSTRAINT fk_address_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
) COMMENT='Patient address details (FHIR: Patient.address), supports multiple addresses per patient for different uses and periods';


-- Patient Contact Table
CREATE TABLE insaights_contact ( -- Patient Contact Table
  id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for this contact entry (UUID or FHIR id)',
  
  name_prefix            VARCHAR(50) COMMENT 'FHIR: HumanName.prefix (e.g., Dr.)',
  first_name             VARCHAR(50) COMMENT 'FHIR: HumanName.given[0] -- first/given name of contact',
  middle_name            VARCHAR(50) COMMENT 'FHIR: HumanName.given[1] -- optional middle name',
  last_name              VARCHAR(100) COMMENT 'FHIR: HumanName.family -- family/last name of contact',
  name_suffix            VARCHAR(50) COMMENT 'FHIR: HumanName.suffix (e.g., PhD)',
  name_text              VARCHAR(200) COMMENT 'FHIR: HumanName.text -- full display name',
  
  address_use 			 VARCHAR(32) COMMENT 'The purpose of this address (e.g., home, work, temporary, old, billing) (FHIR: Address.use)',
  address_type 			 VARCHAR(32) COMMENT 'Type of address: postal, physical, or both (FHIR: Address.type)',
  address_text 			 VARCHAR(200) COMMENT 'Human-readable full address representation (FHIR: Address.text)',
  
  address_line1 		 VARCHAR(128) COMMENT 'Address line 1 (FHIR: Address.line[0])',
  address_line2 		 VARCHAR(128) COMMENT 'Address line 2 (FHIR: Address.line[1])',
  address_line3 		 VARCHAR(128) COMMENT 'Address line 3 (FHIR: Address.line[2])',
  address_line4 		 VARCHAR(128) COMMENT 'Address line 4 (FHIR: Address.line[3])',
  
  address_city 			 VARCHAR(64) COMMENT 'City or locality (FHIR: Address.city)',
  address_district 		 VARCHAR(64) COMMENT 'District or county (FHIR: Address.district)',
  address_state 		 VARCHAR(64) COMMENT 'State, province, or region (FHIR: Address.state)',
  address_postal_code 	 VARCHAR(20) COMMENT 'Postal or ZIP code (FHIR: Address.postalCode)',
  adress_country 		 VARCHAR(64) COMMENT 'Country name (FHIR: Address.country)',
  
  address_period_start 	 DATETIME COMMENT 'Start date for which this address is valid (FHIR: Address.period.start)',
  address_period_end 	 DATETIME COMMENT 'End date for which this address is valid (FHIR: Address.period.end)',

  gender          		VARCHAR(32) COMMENT 'Administrative gender of the contact (male, female, other, unknown)',
  organization_id 		VARCHAR(64) COMMENT 'FK to Organization -- affiliation of the contact person',
  period_start    		DATETIME COMMENT 'Start of validity period for this contact (FHIR: Period.start)',
  period_end      		DATETIME COMMENT 'End of validity period for this contact (FHIR: Period.end)',

  patient_id      		VARCHAR(64) NOT NULL COMMENT 'FK to Patient -- patient this contact is associated with',

  CONSTRAINT fk_contact_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
  CONSTRAINT fk_contact_org FOREIGN KEY (organization_id) REFERENCES insaights_organisation(id)
) COMMENT = 'FHIR Patient.contact: Represents one or more contacts for a patient, such as next-of-kin or emergency contacts, including names, gender, organization, and period of validity';


CREATE TABLE insaights_contact_relationship ( -- Patient Contact Relationship Table
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for this contact-relationship entry (UUID or FHIR id)',
    
    relationship_code 	VARCHAR(32) COMMENT 'Code indicating the relationship type (e.g., next-of-kin, employer, billing, emergency contact)',
    contact_id 			VARCHAR(64) NOT NULL COMMENT 'FK to Contact -- the contact to whom this relationship applies',
    
    CONSTRAINT fk_crel_contact FOREIGN KEY (contact_id) REFERENCES insaights_contact(id)
) COMMENT = 'FHIR Patient.contact.relationship: Represents multiple roles or relationships a contact can have with the patient, allowing one contact to have multiple relationship codes';


CREATE TABLE insaights_contact_telecom ( -- Patient Contact Telecom Table
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for this telecom entry (UUID or FHIR id)',
    
    `system` 			VARCHAR(32) COMMENT 'Telecom system type (e.g., phone, fax, email, pager, url, sms, other)',
    `value` 			VARCHAR(128) COMMENT 'Actual contact value (e.g., phone number, email address, URL)',
    `use` 				VARCHAR(32) COMMENT 'Usage type (e.g., home, work, temp, old, mobile)',
    `rank` 				INT UNSIGNED COMMENT 'Priority of this contact point; lower number = higher priority',
    period_start 		DATETIME COMMENT 'Start date when this contact point is valid/active',
    period_end 			DATETIME COMMENT 'End date when this contact point is valid/active',
    
    contact_id 			VARCHAR(64) NOT NULL COMMENT 'FK to Contact -- the contact this telecom belongs to',
    
    CONSTRAINT fk_ctelecom_contact FOREIGN KEY (contact_id) REFERENCES insaights_contact(id)
) COMMENT = 'FHIR Patient.contact.telecom: Stores multiple communication points for a contact person, allowing different systems, usage, and priority';


CREATE TABLE insaights_communication ( -- Patient communication preferences, preferred languages (FHIR: Patient.communication)
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for this communication entry (UUID or FHIR id)',
    
    patient_id      	VARCHAR(64) NOT NULL COMMENT 'FK to Patient; identifies the patient this communication preference belongs to',
    language_code   	VARCHAR(32) NOT NULL COMMENT 'Code representing the language (e.g., en, hi, fr)',
    preferred       	BOOLEAN DEFAULT FALSE COMMENT 'Indicates if this is the patient’s preferred language (TRUE/FALSE)',
    
    CONSTRAINT fk_comm_patient FOREIGN KEY (patient_id) REFERENCES insaights_patient(id)
) COMMENT='Patient communication preferences, preferred languages';


CREATE TABLE insaights_patient_link ( -- Links patients to other patients or related persons (FHIR: Patient.link)
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for this patient link entry (UUID or FHIR id)',
    
    other_patient_id  	VARCHAR(64) COMMENT 'FK to another Patient; represents a linked patient (optional)',
    related_person_id 	VARCHAR(64) COMMENT 'FK to a RelatedPerson; represents a linked related person (optional)',
    
    `type`       		VARCHAR(32) NOT NULL COMMENT 'Type of link (e.g., replaced-by, replaces, refer, seealso)',
    patient_id   		VARCHAR(64) NOT NULL COMMENT 'FK to the main Patient to whom this link belongs',
    
    CONSTRAINT UNIQUE(patient_id, type) COMMENT 'Ensures only one link of each type per patient',
    CONSTRAINT fk_link_patient        FOREIGN KEY (patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_link_other_patient  FOREIGN KEY (other_patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_link_related_person FOREIGN KEY (related_person_id) REFERENCES insaights_related_person(id),
    
    CONSTRAINT chk_link 
		CHECK (
			(other_patient_id IS NOT NULL AND related_person_id IS NULL)	OR
			(other_patient_id IS NULL AND related_person_id IS NOT NULL)
		)
) COMMENT='helps in duplcate check and updates';
