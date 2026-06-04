------- Patient Resource ----------
CREATE TABLE insaights_codeable_concept(
    concept_type TEXT NOT NULL, -- stores encounter status, act priorityetc.
    code TEXT NOT NULL, -- stores planned, in-progress etc.
    system TEXT,
    display TEXT,
    text TEXT,
    PRIMARY KEY (concept_type, code)
);

COMMENT ON TABLE insaights_codeable_concept
IS 'Lookup table for centralised/decentralised codeable concepts';

COMMENT ON COLUMN insaights_codeable_concept.concept_type
IS 'Defines the category of the concept';

COMMENT ON COLUMN insaights_codeable_concept.code
IS 'Code value within the concept type';

COMMENT ON COLUMN insaights_codeable_concept.system
IS 'URI that identifies the terminology system t';

COMMENT ON COLUMN insaights_codeable_concept.display
IS 'Human-readable display name for the code';

COMMENT ON COLUMN insaights_codeable_concept.text
IS 'Optional free-text description provided by the user';

COMMENT ON CONSTRAINT insaights_codeable_concept_pkey
ON insaights_codeable_concept
IS 'Composite primary key ensuring uniqueness within each concept type';

-------------------------------------------------------
CREATE TABLE insaights_organisation (
    org_id UUID PRIMARY KEY,
	
    name TEXT NOT NULL,
    type TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE insaights_organisation
IS 'Master table storing healthcare organisations such as hospitals, clinics, and related facilities';

COMMENT ON COLUMN insaights_organisation.org_id
IS 'System-generated UUID uniquely identifying the organisation';

COMMENT ON COLUMN insaights_organisation.name
IS 'Official registered name of the healthcare organisation';

COMMENT ON COLUMN insaights_organisation.type
IS 'Classification of the organisation (e.g., hospital, clinic, diagnostic center)';

COMMENT ON COLUMN insaights_organisation.address
IS 'Primary registered address of the organisation';

COMMENT ON COLUMN insaights_organisation.phone
IS 'Primary contact phone number for the organisation';

COMMENT ON COLUMN insaights_organisation.email
IS 'Official contact email address of the organisation';

COMMENT ON COLUMN insaights_organisation.active
IS 'Indicates whether the organisation is currently active (TRUE) or inactive (FALSE)';

-----------------------------------------

CREATE TABLE insaights_attachment (
    attachment_id UUID PRIMARY KEY,
    content_type TEXT,
    content_language TEXT,
    url TEXT,
    content_data BYTEA,
    title TEXT,
    size INTEGER,
    content_hash BYTEA,
    creation_date TIMESTAMPTZ
);

COMMENT ON TABLE insaights_attachment
IS 'FHIR Attachment resource used to store patient-related documents such as ABHA card scans, photos, and supporting files';

COMMENT ON COLUMN insaights_attachment.attachment_id
IS 'Unique identifier for the attachment record';

COMMENT ON COLUMN insaights_attachment.content_type
IS 'MIME type of the attachment content (e.g., image/jpeg, application/pdf)';

COMMENT ON COLUMN insaights_attachment.content_language
IS 'Language of the attachment content as defined in FHIR Attachment.language';

COMMENT ON COLUMN insaights_attachment.url
IS 'External URL where the attachment is stored when not persisted in the database';

COMMENT ON COLUMN insaights_attachment.content_data
IS 'Binary content of the attachment stored inline (e.g., ABHA card image, patient photo)';

COMMENT ON COLUMN insaights_attachment.title
IS 'Human-readable title or label describing the attachment';

COMMENT ON COLUMN insaights_attachment.size
IS 'Size of the attachment file in bytes';

COMMENT ON COLUMN insaights_attachment.content_hash
IS 'Cryptographic hash of the attachment content used for integrity verification';

COMMENT ON COLUMN insaights_attachment.creation_date
IS 'Timestamp indicating when the attachment was created';

-------------------------------------

CREATE TABLE insaights_patient (
    patient_id UUID PRIMARY KEY,

    name_prefix   TEXT,
    first_name    TEXT,
    middle_name   TEXT,
    last_name     TEXT,
    name_suffix   TEXT,
    full_name     TEXT,

    active        BOOLEAN,

    gender        TEXT,-- code valuset
    birth_date    DATE,

    deceased_boolean   BOOLEAN,
    deceased_datetime  TIMESTAMPTZ,   -- (was DATETIME)

    marital_status_code TEXT,

    multiple_birth_boolean BOOLEAN,
    multiple_birth_integer INT,

    photo_id     UUID, 
    religion     TEXT,
    annual_income INT,
    nationality  TEXT,

    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by   TEXT NOT NULL,
    modified_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by  TEXT NOT NULL DEFAULT 'SYSTEM',

    managing_organization_id UUID,

    CONSTRAINT chk_deceased
      CHECK (
        (deceased_boolean = TRUE  AND deceased_datetime IS NOT NULL) OR
        (deceased_boolean = FALSE AND deceased_datetime IS NULL)
      ),

    CONSTRAINT chk_mul_birth
      CHECK (
        (multiple_birth_boolean = TRUE  AND multiple_birth_integer IS NOT NULL) OR
        (multiple_birth_boolean = FALSE AND multiple_birth_integer IS NULL)
      ),

    CONSTRAINT fk_patient_attachment
      FOREIGN KEY (photo_id) REFERENCES insaights_attachment(attachment_id),

    CONSTRAINT fk_patient_org
      FOREIGN KEY (managing_organization_id) REFERENCES insaights_organisation(org_id)
);

COMMENT ON TABLE insaights_patient
IS 'FHIR Patient resource representation storing demographic and administrative patient data';

COMMENT ON COLUMN insaights_patient.patient_id
IS 'Unique identifier for the patient resource (FHIR Patient.id); typically a UUID or system-generated identifier';

COMMENT ON COLUMN insaights_patient.name_prefix
IS 'Name prefix component (FHIR HumanName.prefix), e.g., Mr, Ms, Dr';

COMMENT ON COLUMN insaights_patient.first_name
IS 'Given name / first name (FHIR HumanName.given[0])';

COMMENT ON COLUMN insaights_patient.middle_name
IS 'Additional given name / middle name (FHIR HumanName.given[1]), when available';

COMMENT ON COLUMN insaights_patient.last_name
IS 'Family name / surname (FHIR HumanName.family)';

COMMENT ON COLUMN insaights_patient.name_suffix
IS 'Name suffix component (FHIR HumanName.suffix), e.g., Jr, Sr, PhD';

COMMENT ON COLUMN insaights_patient.full_name
IS 'Full display name for presentation (FHIR HumanName.text)';

COMMENT ON COLUMN insaights_patient.active
IS 'Indicates whether the patient record is active (FHIR Patient.active)';

COMMENT ON COLUMN insaights_patient.gender
IS 'Administrative gender (FHIR Patient.gender), e.g., male, female, other, unknown';

COMMENT ON COLUMN insaights_patient.birth_date
IS 'Date of birth (FHIR Patient.birthDate)';

COMMENT ON COLUMN insaights_patient.deceased_boolean
IS 'Indicates whether the patient is deceased (FHIR Patient.deceasedBoolean)';

COMMENT ON COLUMN insaights_patient.deceased_dateTime
IS 'Date/time of death when known (FHIR Patient.deceasedDateTime)';

COMMENT ON COLUMN insaights_patient.marital_status_code
IS 'Marital status code (FHIR Patient.maritalStatus.coding.code)';

COMMENT ON COLUMN insaights_patient.multiple_birth_boolean
IS 'Indicates whether the patient is part of a multiple birth (FHIR Patient.multipleBirthBoolean)';

COMMENT ON COLUMN insaights_patient.multiple_birth_integer
IS 'Birth order in a multiple birth (FHIR Patient.multipleBirthInteger)';

COMMENT ON COLUMN insaights_patient.photo_id
IS 'Reference to an attachment record for the patient photo or document (FK to insaights_attachment)';

COMMENT ON COLUMN insaights_patient.religion
IS 'Patient religion captured for administrative or facility-specific workflows (not a core FHIR element)';

COMMENT ON COLUMN insaights_patient.annual_income
IS 'Annual income for administrative purposes when collected (non-clinical attribute)';

COMMENT ON COLUMN insaights_patient.nationality
IS 'Patient nationality for administrative and reporting purposes';

COMMENT ON COLUMN insaights_patient.created_at
IS 'Timestamp when the record was created';

COMMENT ON COLUMN insaights_patient.created_by
IS 'Identifier of the user or system that created the record';

COMMENT ON COLUMN insaights_patient.modified_at
IS 'Timestamp when the record was last updated';

COMMENT ON COLUMN insaights_patient.modified_by
IS 'Identifier of the user or system that last updated the record';

COMMENT ON COLUMN insaights_patient.managing_organization_id
IS 'Organisation responsible for maintaining the patient record (FHIR Patient.managingOrganization; FK to insaights_organisation)';

------------------------------------

CREATE TABLE insaights_practitioner (
    practitioner_id UUID PRIMARY KEY,
    given_name TEXT,
    family_name TEXT,
    gender TEXT,
    birth_date DATE,
    phone TEXT,
    email TEXT,
    active BOOLEAN DEFAULT TRUE
);


COMMENT ON TABLE insaights_practitioner
IS 'FHIR Practitioner resource representing healthcare professionals who provide direct patient care';

COMMENT ON COLUMN insaights_practitioner.practitioner_id
IS 'Unique system-generated identifier for the practitioner (FHIR Practitioner.id)';

COMMENT ON COLUMN insaights_practitioner.given_name
IS 'Practitioner given or first name (FHIR HumanName.given)';

COMMENT ON COLUMN insaights_practitioner.family_name
IS 'Practitioner family or last name (FHIR HumanName.family)';

COMMENT ON COLUMN insaights_practitioner.gender
IS 'Administrative gender of the practitioner (FHIR Practitioner.gender)';

COMMENT ON COLUMN insaights_practitioner.birth_date
IS 'Date of birth of the practitioner';

COMMENT ON COLUMN insaights_practitioner.phone
IS 'Primary contact phone number for the practitioner';

COMMENT ON COLUMN insaights_practitioner.email
IS 'Professional or official email address of the practitioner';

COMMENT ON COLUMN insaights_practitioner.active
IS 'Indicates whether the practitioner is currently active and eligible to provide services';
------------------------------

CREATE TABLE insaights_practitioner_role (
    practitioner_role_id UUID PRIMARY KEY,
    practitioner_id UUID,
    organization_id UUID,
    role TEXT,
    specialty TEXT,
    contact_number TEXT,
    email TEXT,
    available_start TIMESTAMPTZ,
    available_end TIMESTAMPTZ,
    active BOOLEAN DEFAULT TRUE,
    notes TEXT
);

COMMENT ON TABLE insaights_practitioner_role
IS 'FHIR PractitionerRole resource defining roles, responsibilities, and organizational associations of healthcare practitioners';

COMMENT ON COLUMN insaights_practitioner_role.practitioner_role_id
IS 'Unique identifier for the practitioner role record (FHIR PractitionerRole.id)';

COMMENT ON COLUMN insaights_practitioner_role.practitioner_id
IS 'Reference to the practitioner performing this role (FK to insaights_practitioner)';

COMMENT ON COLUMN insaights_practitioner_role.organization_id
IS 'Reference to the organization where the practitioner performs this role (FK to insaights_organisation)';

COMMENT ON COLUMN insaights_practitioner_role.role
IS 'Role or function of the practitioner within the organization (e.g., Doctor, Nurse, Surgeon)';

COMMENT ON COLUMN insaights_practitioner_role.specialty
IS 'Clinical or professional specialty associated with the practitioner role (e.g., Cardiology, Pediatrics)';

COMMENT ON COLUMN insaights_practitioner_role.contact_number
IS 'Primary contact phone number associated with this practitioner role';

COMMENT ON COLUMN insaights_practitioner_role.email
IS 'Professional contact email associated with this practitioner role';

COMMENT ON COLUMN insaights_practitioner_role.available_start
IS 'Start timestamp of the practitioner’s availability period for this role';

COMMENT ON COLUMN insaights_practitioner_role.available_end
IS 'End timestamp of the practitioner’s availability period for this role';

COMMENT ON COLUMN insaights_practitioner_role.active
IS 'Indicates whether this practitioner role is currently active';

COMMENT ON COLUMN insaights_practitioner_role.notes
IS 'Additional notes or descriptive information about the practitioner role';

---------------------------------

CREATE TABLE insaights_general_practitioner (
    general_practitioner_id UUID PRIMARY KEY,
    
    organisation_id UUID,
    practitioner_id UUID,
    practitioner_role_id UUID,
    patient_id UUID NOT NULL,

    CONSTRAINT fk_gp_patient
        FOREIGN KEY (patient_id)
        REFERENCES insaights_patient(patient_id),

    CONSTRAINT fk_gp_org
        FOREIGN KEY (organisation_id)
        REFERENCES insaights_organisation(org_id),

    CONSTRAINT fk_gp_practitioner_role
        FOREIGN KEY (practitioner_role_id)
        REFERENCES insaights_practitioner_role(practitioner_role_id),

    CONSTRAINT fk_gp_practitioner
        FOREIGN KEY (practitioner_id)
        REFERENCES insaights_practitioner(practitioner_id),

    CONSTRAINT chk_gp_only_one_reference CHECK (
        (practitioner_id IS NOT NULL AND organisation_id IS NULL AND practitioner_role_id IS NULL) OR
        (practitioner_id IS NULL AND organisation_id IS NOT NULL AND practitioner_role_id IS NULL) OR
        (practitioner_id IS NULL AND organisation_id IS NULL AND practitioner_role_id IS NOT NULL)
    )
);

COMMENT ON TABLE insaights_general_practitioner
IS 'Association table linking patients to their general practitioner reference, which may be a practitioner, organisation, or practitioner role';

COMMENT ON COLUMN insaights_general_practitioner.general_practitioner_id
IS 'Unique identifier for the general practitioner association record';

COMMENT ON COLUMN insaights_general_practitioner.organisation_id
IS 'Reference to the healthcare organisation acting as the general practitioner for the patient';

COMMENT ON COLUMN insaights_general_practitioner.practitioner_id
IS 'Reference to an individual practitioner acting as the general practitioner for the patient';

COMMENT ON COLUMN insaights_general_practitioner.practitioner_role_id
IS 'Reference to a practitioner role acting as the general practitioner for the patient';

COMMENT ON COLUMN insaights_general_practitioner.patient_id
IS 'Reference to the patient to whom the general practitioner association applies';

COMMENT ON CONSTRAINT fk_gp_patient ON insaights_general_practitioner
IS 'Foreign key linking the association to the patient record';

COMMENT ON CONSTRAINT fk_gp_org ON insaights_general_practitioner
IS 'Foreign key linking the association to an organisation acting as general practitioner';

COMMENT ON CONSTRAINT fk_gp_practitioner_role ON insaights_general_practitioner
IS 'Foreign key linking the association to a practitioner role acting as general practitioner';

COMMENT ON CONSTRAINT fk_gp_practitioner ON insaights_general_practitioner
IS 'Foreign key linking the association to an individual practitioner acting as general practitioner';

COMMENT ON CONSTRAINT chk_gp_only_one_reference ON insaights_general_practitioner
IS 'Ensures exactly one general practitioner reference is provided: practitioner, organisation, or practitioner role';
----------------------------

CREATE TABLE insaights_related_person (
    related_person_id UUID PRIMARY KEY,

    patient_id UUID NOT NULL,
    name_text TEXT,
    relationship_code TEXT,
    gender TEXT,
    birth_date DATE,
    telecom TEXT,
    address TEXT,
    active BOOLEAN DEFAULT TRUE,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_related_person_patient
        FOREIGN KEY (patient_id)
        REFERENCES insaights_patient(patient_id)
);

COMMENT ON TABLE insaights_related_person
IS 'FHIR RelatedPerson resource representing individuals involved in a patient’s care, such as family members or caregivers';

COMMENT ON COLUMN insaights_related_person.related_person_id
IS 'Unique identifier for the related person resource (FHIR RelatedPerson.id)';

COMMENT ON COLUMN insaights_related_person.patient_id
IS 'Reference to the patient with whom this person is associated';

COMMENT ON COLUMN insaights_related_person.name_text
IS 'Full name of the related person for display purposes';

COMMENT ON COLUMN insaights_related_person.relationship_code
IS 'Coded relationship type describing how the person is related to the patient (e.g., mother, spouse, guardian)';

COMMENT ON COLUMN insaights_related_person.gender
IS 'Administrative gender of the related person';

COMMENT ON COLUMN insaights_related_person.birth_date
IS 'Date of birth of the related person, when known';

COMMENT ON COLUMN insaights_related_person.telecom
IS 'Contact details for the related person, such as phone number or email address';

COMMENT ON COLUMN insaights_related_person.address
IS 'Residential or mailing address of the related person';

COMMENT ON COLUMN insaights_related_person.active
IS 'Indicates whether the related person record is currently active';

COMMENT ON COLUMN insaights_related_person.period_start
IS 'Start date and time from which the relationship to the patient is considered valid';

COMMENT ON COLUMN insaights_related_person.period_end
IS 'End date and time until which the relationship to the patient is considered valid';

COMMENT ON COLUMN insaights_related_person.created_at
IS 'Timestamp indicating when the related person record was created';

COMMENT ON CONSTRAINT fk_related_person_patient ON insaights_related_person
IS 'Foreign key linking the related person record to the associated patient';
--------------------------------------

CREATE TABLE insaights_identifier (
    identifier_id UUID PRIMARY KEY,

    use TEXT, -- code 
    type TEXT, -- codeable concept
    system TEXT,
    value TEXT,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,

    photo_attachment_id UUID,
    assigner_id UUID,

    patient_id UUID NOT NULL,

    CONSTRAINT fk_identifier_patient
        FOREIGN KEY (patient_id)
        REFERENCES insaights_patient(patient_id),

    CONSTRAINT fk_identifier_attachment
        FOREIGN KEY (photo_attachment_id)
        REFERENCES insaights_attachment(attachment_id),

    CONSTRAINT fk_identifier_assigner
        FOREIGN KEY (assigner_id)
        REFERENCES insaights_organisation(org_id),

	CONSTRAINT uq_patient_type UNIQUE (patient_id),
	CONSTRAINT uq_system_value UNIQUE (system, value)
);

-- ALTER TABLE insaights_identifier
-- ADD CONSTRAINT uq_patient_type UNIQUE (patient_id, type);
-- ALTER TABLE insaights_identifier
-- ADD CONSTRAINT uq_system_value UNIQUE (system, value);

COMMENT ON CONSTRAINT uq_patient_type ON insaights_identifier IS
'Ensures that each patient can have at most one identifier per identifier type. Prevents duplicate identifier types (e.g., multiple AADHAR records) for the same patient.';
COMMENT ON CONSTRAINT uq_system_value ON insaights_identifier IS
'Ensures global uniqueness of an identifier within its issuing system. Prevents the same identifier value from being associated with multiple patients.';

COMMENT ON TABLE insaights_identifier
IS 'FHIR Identifier resource storing patient identifiers such as MRN, passport numbers, and other official identifiers';

COMMENT ON COLUMN insaights_identifier.identifier_id
IS 'Unique identifier for the identifier record (FHIR Identifier.id)';

COMMENT ON COLUMN insaights_identifier.use
IS 'Intended use of the identifier (FHIR Identifier.use), such as official, usual, secondary, or temporary';

COMMENT ON COLUMN insaights_identifier.type
IS 'Code describing the type of identifier (FHIR Identifier.type), e.g., medical record number, passport, driver license';

COMMENT ON COLUMN insaights_identifier.system
IS 'Namespace or issuing system for the identifier (FHIR Identifier.system), expressed as a URI, OID, or URL';

COMMENT ON COLUMN insaights_identifier.value
IS 'Actual identifier value assigned to the patient (FHIR Identifier.value)';

COMMENT ON COLUMN insaights_identifier.period_start
IS 'Start date and time from which the identifier is considered valid (FHIR Identifier.period.start)';

COMMENT ON COLUMN insaights_identifier.period_end
IS 'End date and time after which the identifier is no longer valid (FHIR Identifier.period.end)';

COMMENT ON COLUMN insaights_identifier.photo_attachment_id
IS 'Optional reference to an attachment associated with the identifier, such as an ID card image';

COMMENT ON COLUMN insaights_identifier.assigner_id
IS 'Reference to the organisation that issued or assigned the identifier (FHIR Identifier.assigner)';

COMMENT ON COLUMN insaights_identifier.patient_id
IS 'Reference to the patient to whom this identifier belongs';

COMMENT ON CONSTRAINT fk_identifier_patient ON insaights_identifier
IS 'Foreign key linking the identifier to the associated patient';

COMMENT ON CONSTRAINT fk_identifier_attachment ON insaights_identifier
IS 'Foreign key linking the identifier to an associated attachment';

COMMENT ON CONSTRAINT fk_identifier_assigner ON insaights_identifier
IS 'Foreign key linking the identifier to the issuing organisation';
-----------------------------------

CREATE TABLE insaights_telecom (
    telecom_id UUID PRIMARY KEY,

    system TEXT,
    value TEXT,
    use TEXT,
    rank INTEGER,

    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,

    patient_id UUID NOT NULL,

    CONSTRAINT fk_telecom_patient
        FOREIGN KEY (patient_id)
        REFERENCES insaights_patient(patient_id),

    CONSTRAINT chk_telecom_rank_non_negative
        CHECK (rank IS NULL OR rank >= 0)
);

COMMENT ON TABLE insaights_telecom
IS 'FHIR ContactPoint resource storing telecom details such as phone numbers, email addresses, and other contact information for a patient';

COMMENT ON COLUMN insaights_telecom.telecom_id
IS 'Unique identifier for the telecom contact record';

COMMENT ON COLUMN insaights_telecom.system
IS 'Type of contact system (FHIR ContactPoint.system), such as phone, email, fax, or URL';

COMMENT ON COLUMN insaights_telecom.value
IS 'Actual contact detail value, such as a phone number or email address (FHIR ContactPoint.value)';

COMMENT ON COLUMN insaights_telecom.use
IS 'Intended usage of the contact detail (FHIR ContactPoint.use), such as home, work, mobile, temporary, or old';

COMMENT ON COLUMN insaights_telecom.rank
IS 'Priority order of this contact detail, where a lower number indicates higher priority (FHIR ContactPoint.rank)';

COMMENT ON COLUMN insaights_telecom.period_start
IS 'Start date and time from which this contact detail is considered valid (FHIR ContactPoint.period.start)';

COMMENT ON COLUMN insaights_telecom.period_end
IS 'End date and time until which this contact detail is considered valid; NULL indicates the contact is still active (FHIR ContactPoint.period.end)';

COMMENT ON COLUMN insaights_telecom.patient_id
IS 'Reference to the patient who owns this telecom contact detail';

COMMENT ON CONSTRAINT fk_telecom_patient ON insaights_telecom
IS 'Foreign key linking the telecom record to the associated patient';

COMMENT ON CONSTRAINT chk_telecom_rank_non_negative ON insaights_telecom
IS 'Ensures telecom rank values are non-negative';
--------------------------------

CREATE TABLE insaights_address (
    address_id UUID PRIMARY KEY,

    use TEXT,
    type TEXT,
    text TEXT,

    line1 TEXT,
    line2 TEXT,
    line3 TEXT,
    line4 TEXT,

    city TEXT,
    district TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT,

    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,

    patient_id UUID NOT NULL,

    CONSTRAINT fk_address_patient
        FOREIGN KEY (patient_id)
        REFERENCES insaights_patient(patient_id)
);

COMMENT ON TABLE insaights_address
IS 'FHIR Address element captured for a patient, supporting multiple addresses by use/type and validity period';

COMMENT ON COLUMN insaights_address.address_id
IS 'Unique identifier for the address record (FHIR Address.id when persisted)';

COMMENT ON COLUMN insaights_address.use
IS 'Purpose of the address (FHIR Address.use), such as home, work, temporary, old, or billing';

COMMENT ON COLUMN insaights_address.type
IS 'Type of address (FHIR Address.type), such as postal, physical, or both';

COMMENT ON COLUMN insaights_address.text
IS 'Full address expressed as human-readable text (FHIR Address.text)';

COMMENT ON COLUMN insaights_address.line1
IS 'Address line 1 (FHIR Address.line[0])';

COMMENT ON COLUMN insaights_address.line2
IS 'Address line 2 (FHIR Address.line[1])';

COMMENT ON COLUMN insaights_address.line3
IS 'Address line 3 (FHIR Address.line[2])';

COMMENT ON COLUMN insaights_address.line4
IS 'Address line 4 (FHIR Address.line[3])';

COMMENT ON COLUMN insaights_address.city
IS 'City, town, or locality (FHIR Address.city)';

COMMENT ON COLUMN insaights_address.district
IS 'District, county, or administrative area (FHIR Address.district)';

COMMENT ON COLUMN insaights_address.state
IS 'State, province, or region (FHIR Address.state)';

COMMENT ON COLUMN insaights_address.postal_code
IS 'Postal or ZIP code (FHIR Address.postalCode)';

COMMENT ON COLUMN insaights_address.country
IS 'Country name (FHIR Address.country)';

COMMENT ON COLUMN insaights_address.period_start
IS 'Start timestamp from which the address is considered valid (FHIR Address.period.start)';

COMMENT ON COLUMN insaights_address.period_end
IS 'End timestamp until which the address is considered valid; NULL indicates the address is still valid (FHIR Address.period.end)';

COMMENT ON COLUMN insaights_address.patient_id
IS 'Reference to the patient who owns this address';

COMMENT ON CONSTRAINT fk_address_patient ON insaights_address
IS 'Foreign key linking the address record to the associated patient';
-------------------------------------

CREATE TABLE insaights_contact (
    contact_id UUID PRIMARY KEY,

    patient_id UUID NOT NULL,

    name_prefix TEXT,
    first_name TEXT,
    middle_name TEXT,
    last_name TEXT,
    name_suffix TEXT,
    name_text TEXT,

    address_use TEXT,
    address_type TEXT,
    address_text TEXT,

    address_line1 TEXT,
    address_line2 TEXT,
    address_line3 TEXT,
    address_line4 TEXT,

    address_city TEXT,
    address_district TEXT,
    address_state TEXT,
    address_postal_code TEXT,
    address_country TEXT,

    address_period_start TIMESTAMPTZ,
    address_period_end TIMESTAMPTZ,

    gender TEXT,
    organization_id UUID,

    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,

    CONSTRAINT fk_contact_patient
        FOREIGN KEY (patient_id)
        REFERENCES insaights_patient(patient_id),

    CONSTRAINT fk_contact_org
        FOREIGN KEY (organization_id)
        REFERENCES insaights_organisation(org_id)
);

COMMENT ON TABLE insaights_contact
IS 'FHIR Patient.contact element representing one or more contact persons for a patient, such as next-of-kin or emergency contacts';

COMMENT ON COLUMN insaights_contact.contact_id
IS 'Unique identifier for the patient contact record';

COMMENT ON COLUMN insaights_contact.patient_id
IS 'Reference to the patient to whom this contact is associated';

COMMENT ON COLUMN insaights_contact.organization_id
IS 'Reference to an organisation associated with the contact person';

COMMENT ON COLUMN insaights_contact.period_start
IS 'Start timestamp of the validity period for this contact relationship';

COMMENT ON COLUMN insaights_contact.period_end
IS 'End timestamp of the validity period for this contact relationship';
-------------------------------------

CREATE TABLE insaights_contact_relationship (
    contact_relationship_id UUID PRIMARY KEY,

    relationship_code TEXT,
    contact_id UUID NOT NULL,

    CONSTRAINT fk_crel_contact
        FOREIGN KEY (contact_id)
        REFERENCES insaights_contact(contact_id)
);

COMMENT ON TABLE insaights_contact_relationship
IS 'FHIR Patient.contact.relationship element allowing a single contact to carry multiple relationship or role codes with respect to the patient';

COMMENT ON COLUMN insaights_contact_relationship.contact_relationship_id
IS 'Unique identifier for the contact relationship record';

COMMENT ON COLUMN insaights_contact_relationship.relationship_code
IS 'Relationship or role code describing the contact’s association to the patient (e.g., emergency contact, next-of-kin, billing)';

COMMENT ON COLUMN insaights_contact_relationship.contact_id
IS 'Reference to the patient contact record to which this relationship code applies';

COMMENT ON CONSTRAINT fk_crel_contact ON insaights_contact_relationship
IS 'Foreign key linking the relationship entry to a patient contact record';
-------------------------------------

CREATE TABLE insaights_contact_telecom (
    contact_telecom_id UUID PRIMARY KEY,

    system TEXT,
    value TEXT,
    use TEXT,
    rank INTEGER,

    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,

    contact_id UUID NOT NULL,

    CONSTRAINT fk_ctelecom_contact
        FOREIGN KEY (contact_id)
        REFERENCES insaights_contact(contact_id),

    CONSTRAINT chk_contact_telecom_rank_non_negative
        CHECK (rank IS NULL OR rank >= 0)
);

COMMENT ON TABLE insaights_contact_telecom
IS 'FHIR Patient.contact.telecom element storing multiple communication points for a contact person, including system, usage, priority, and validity period';

COMMENT ON COLUMN insaights_contact_telecom.contact_telecom_id
IS 'Unique identifier for the contact telecom record';

COMMENT ON COLUMN insaights_contact_telecom.system
IS 'Telecom system type (FHIR ContactPoint.system), such as phone, fax, email, pager, URL, SMS, or other';

COMMENT ON COLUMN insaights_contact_telecom.value
IS 'Actual contact value for the telecom system, such as a phone number, email address, or URL (FHIR ContactPoint.value)';

COMMENT ON COLUMN insaights_contact_telecom.use
IS 'Intended usage of the telecom contact point (FHIR ContactPoint.use), such as home, work, temporary, old, or mobile';

COMMENT ON COLUMN insaights_contact_telecom.rank
IS 'Priority order of the telecom contact point, where a lower number indicates higher priority (FHIR ContactPoint.rank)';

COMMENT ON COLUMN insaights_contact_telecom.period_start
IS 'Start timestamp from which the telecom contact point is considered valid (FHIR ContactPoint.period.start)';

COMMENT ON COLUMN insaights_contact_telecom.period_end
IS 'End timestamp until which the telecom contact point is considered valid; NULL indicates the contact point is still active (FHIR ContactPoint.period.end)';

COMMENT ON COLUMN insaights_contact_telecom.contact_id
IS 'Reference to the patient contact record to which this telecom contact point belongs';

COMMENT ON CONSTRAINT fk_ctelecom_contact ON insaights_contact_telecom
IS 'Foreign key linking the telecom contact record to the associated patient contact';

COMMENT ON CONSTRAINT chk_contact_telecom_rank_non_negative ON insaights_contact_telecom
IS 'Ensures that telecom rank values are non-negative';
----------------------------

CREATE TABLE insaights_communication (
    communication_id UUID PRIMARY KEY,

    patient_id UUID NOT NULL,
    language_code TEXT NOT NULL,
    preferred BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_comm_patient
        FOREIGN KEY (patient_id)
        REFERENCES insaights_patient(patient_id)
);

COMMENT ON TABLE insaights_communication
IS 'FHIR Patient.communication element storing patient language preferences and communication requirements';

COMMENT ON COLUMN insaights_communication.communication_id
IS 'Unique identifier for the patient communication preference record';

COMMENT ON COLUMN insaights_communication.patient_id
IS 'Reference to the patient to whom this communication preference applies';

COMMENT ON COLUMN insaights_communication.language_code
IS 'Language code representing the patient’s spoken or preferred language (FHIR Patient.communication.language)';

COMMENT ON COLUMN insaights_communication.preferred
IS 'Indicates whether this language is marked as the patient’s preferred language';

COMMENT ON CONSTRAINT fk_comm_patient ON insaights_communication
IS 'Foreign key linking the communication preference record to the associated patient';
----------------------


CREATE TABLE insaights_patient_link (
    patient_link_id UUID PRIMARY KEY,

    other_patient_id UUID,
    related_person_id UUID,

    type TEXT NOT NULL,
    patient_id UUID NOT NULL,

    CONSTRAINT uq_patient_link_patient_type
        UNIQUE (patient_id, type),

    CONSTRAINT fk_link_patient
        FOREIGN KEY (patient_id)
        REFERENCES insaights_patient(patient_id),

    CONSTRAINT fk_link_other_patient
        FOREIGN KEY (other_patient_id)
        REFERENCES insaights_patient(patient_id),

    CONSTRAINT fk_link_related_person
        FOREIGN KEY (related_person_id)
        REFERENCES insaights_related_person(related_person_id),

    CONSTRAINT chk_patient_link_one_target
        CHECK (
            (other_patient_id IS NOT NULL AND related_person_id IS NULL) OR
            (other_patient_id IS NULL AND related_person_id IS NOT NULL)
        )
);

COMMENT ON TABLE insaights_patient_link
IS 'FHIR Patient.link element used to connect a patient to another patient record or to a related person for deduplication, merging, and cross-referencing';

COMMENT ON COLUMN insaights_patient_link.patient_link_id
IS 'Unique identifier for the patient link record';

COMMENT ON COLUMN insaights_patient_link.other_patient_id
IS 'Reference to another patient record when the link target is a patient';

COMMENT ON COLUMN insaights_patient_link.related_person_id
IS 'Reference to a related person record when the link target is a related person';

COMMENT ON COLUMN insaights_patient_link.type
IS 'Type of link relationship (FHIR Patient.link.type), such as replaced-by, replaces, refer, or seealso';

COMMENT ON COLUMN insaights_patient_link.patient_id
IS 'Reference to the primary patient record to which this link belongs';

COMMENT ON CONSTRAINT uq_patient_link_patient_type ON insaights_patient_link
IS 'Ensures there is at most one link of a given type for a patient';

COMMENT ON CONSTRAINT fk_link_patient ON insaights_patient_link
IS 'Foreign key linking the link record to the primary patient';

COMMENT ON CONSTRAINT fk_link_other_patient ON insaights_patient_link
IS 'Foreign key linking the link record to the target patient, when applicable';

COMMENT ON CONSTRAINT fk_link_related_person ON insaights_patient_link
IS 'Foreign key linking the link record to the target related person, when applicable';

COMMENT ON CONSTRAINT chk_patient_link_one_target ON insaights_patient_link
IS 'Ensures exactly one link target is provided: either other_patient_id or related_person_id';

------------------------------ 16 tables for patient resource ---------

------------ Encounter Resource ---------
-- implementing using db based comments 24 tables + 10tables for refernce fks

CREATE TABLE insaights_group ( --  for reference only not permanent
	id  UUID PRIMARY KEY );

CREATE TABLE insaights_condition ( --  for reference only not permanent
	id  UUID PRIMARY KEY );

CREATE TABLE insaights_episode_of_care ( --  for reference only not permanent
	id  UUID PRIMARY KEY );

CREATE TABLE insaights_care_team ( --  for reference only not permanent
	id  UUID PRIMARY KEY );

CREATE TABLE insaights_appointment ( --  for reference only not permanent
	id  UUID PRIMARY KEY );

CREATE TABLE insaights_account ( --  for reference only not permanent
	id  UUID PRIMARY KEY );

CREATE TABLE insaights_location ( --  for reference only not permanent
	id  UUID PRIMARY KEY );

 CREATE TABLE insaights_healthcare_service ( --  for reference only not permanent
	id  UUID PRIMARY KEY );
  
-------------------------------------- need to discuss about 1 to many

CREATE TABLE insaights_encounter (
    encounter_id UUID PRIMARY KEY,

    status_code TEXT NOT NULL,
    status_set_on_date TIMESTAMPTZ,
    status_set_by_user_id UUID,
    status_reason TEXT,
    adt_status TEXT,
    priority_code TEXT,

    subject_patient_id UUID,
    subject_group_id UUID,

    subject_status_code TEXT,
    part_of_encounter_id UUID,
    service_provider_org_id UUID,

    planned_start TIMESTAMPTZ,
    planned_end TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,

    length_quantity NUMERIC(6,2),
    length_unit TEXT,
    class_code TEXT,

    recall_yn BOOLEAN,
    recall_date DATE,

    patient_type_code TEXT,
    fiscal_year TEXT,
    fiscal_period TEXT,
    shift_id TEXT,

    backdated_yn BOOLEAN NOT NULL,
    brought_dead BOOLEAN NOT NULL,

    priority_zone_code TEXT,
    security_level_code TEXT DEFAULT 'NORMAL',
    protection_ind BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL,
    modified_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by TEXT NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT chk_recall
        CHECK (
            (recall_yn = TRUE AND recall_date IS NOT NULL) OR
            (recall_yn = FALSE AND recall_date IS NULL) 
        ),

    CONSTRAINT chk_pat_grp
        CHECK (
            (subject_patient_id IS NOT NULL AND subject_group_id IS NULL) OR
            (subject_patient_id IS NULL AND subject_group_id IS NOT NULL)
        ),

    CONSTRAINT fk_encounter_subject_patient
        FOREIGN KEY (subject_patient_id) REFERENCES insaights_patient(patient_id),

    CONSTRAINT fk_encounter_subject_group
        FOREIGN KEY (subject_group_id) REFERENCES insaights_group(id),

    CONSTRAINT fk_encounter_part_of
        FOREIGN KEY (part_of_encounter_id) REFERENCES insaights_encounter(encounter_id),

    CONSTRAINT fk_encounter_service_provider
        FOREIGN KEY (service_provider_org_id) REFERENCES insaights_organisation(org_id)
);

CREATE OR REPLACE FUNCTION set_modified_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.modified_at := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_modified_at_ensaights_encounter ON insaights_encounter;

CREATE TRIGGER trg_set_modified_at_ensaights_encounter
BEFORE UPDATE ON insaights_encounter
FOR EACH ROW
EXECUTE FUNCTION set_modified_at();

COMMENT ON TABLE insaights_encounter
IS 'FHIR Encounter resource representing an interaction between a patient (or group) and the healthcare system';

COMMENT ON COLUMN insaights_encounter.encounter_id
IS 'Unique identifier for the encounter record (FHIR Encounter.id)';

COMMENT ON COLUMN insaights_encounter.status_code
IS 'Encounter status (FHIR Encounter.status), e.g., planned, in-progress, on-hold, finished';

COMMENT ON COLUMN insaights_encounter.status_set_on_date
IS 'Timestamp when the current status was assigned';

COMMENT ON COLUMN insaights_encounter.status_set_by_user_id
IS 'Identifier of the user or staff member who set the encounter status';

COMMENT ON COLUMN insaights_encounter.status_reason
IS 'Reason for the most recent status update';

COMMENT ON COLUMN insaights_encounter.adt_status
IS 'Administrative workflow status (facility-specific), e.g., check-in, pre-admit, discharged';

COMMENT ON COLUMN insaights_encounter.priority_code
IS 'Encounter priority code (e.g., routine, ASAP)';

COMMENT ON COLUMN insaights_encounter.subject_patient_id
IS 'Reference to the patient involved in the encounter (FHIR Encounter.subject)';

COMMENT ON COLUMN insaights_encounter.subject_group_id
IS 'Reference to the patient group involved in the encounter, when applicable';

COMMENT ON COLUMN insaights_encounter.subject_status_code
IS 'Patient status during the encounter (facility-specific), e.g., arrived, triaged, on-leave';

COMMENT ON COLUMN insaights_encounter.part_of_encounter_id
IS 'Reference to a parent encounter when this is a sub-encounter (FHIR Encounter.partOf)';

COMMENT ON COLUMN insaights_encounter.service_provider_org_id
IS 'Reference to the organisation providing the service (FHIR Encounter.serviceProvider)';

COMMENT ON COLUMN insaights_encounter.planned_start
IS 'Scheduled start date/time for the encounter';

COMMENT ON COLUMN insaights_encounter.planned_end
IS 'Scheduled end date/time for the encounter';

COMMENT ON COLUMN insaights_encounter.actual_start
IS 'Actual start date/time for the encounter';

COMMENT ON COLUMN insaights_encounter.actual_end
IS 'Actual end date/time for the encounter';

COMMENT ON COLUMN insaights_encounter.length_quantity
IS 'Duration of the encounter expressed as a numeric quantity';

COMMENT ON COLUMN insaights_encounter.length_unit
IS 'Unit of duration (preferably UCUM), e.g., min, h';

COMMENT ON COLUMN insaights_encounter.class_code
IS 'Encounter class or setting (FHIR Encounter.class), e.g., inpatient, outpatient, virtual';

COMMENT ON COLUMN insaights_encounter.recall_yn
IS 'Indicates whether follow-up is required for the encounter';

COMMENT ON COLUMN insaights_encounter.recall_date
IS 'Planned follow-up date when recall is required';

COMMENT ON COLUMN insaights_encounter.patient_type_code
IS 'Patient classification for reporting (facility-specific), e.g., new, returning';

COMMENT ON COLUMN insaights_encounter.fiscal_year
IS 'Fiscal or reporting year for analytics (facility-specific)';

COMMENT ON COLUMN insaights_encounter.fiscal_period
IS 'Fiscal period such as month/quarter for analytics (facility-specific)';

COMMENT ON COLUMN insaights_encounter.shift_id
IS 'Shift identifier during which the encounter occurred (facility-specific)';

COMMENT ON COLUMN insaights_encounter.backdated_yn
IS 'Indicates whether the encounter record was entered as backdated';

COMMENT ON COLUMN insaights_encounter.brought_dead
IS 'Indicates whether the patient was brought dead (facility-specific)';

COMMENT ON COLUMN insaights_encounter.priority_zone_code
IS 'Triage or priority zone code assigned during the encounter (facility-specific), e.g., red/green/blue';

COMMENT ON COLUMN insaights_encounter.security_level_code
IS 'Access restriction level for the encounter record, e.g., NORMAL, RESTRICTED, CONFIDENTIAL';

COMMENT ON COLUMN insaights_encounter.protection_ind
IS 'Indicates whether additional protections or controls apply to this encounter record';

COMMENT ON COLUMN insaights_encounter.created_at
IS 'Timestamp when the encounter record was created';

COMMENT ON COLUMN insaights_encounter.created_by
IS 'Identifier of the user or system that created the encounter record';

COMMENT ON COLUMN insaights_encounter.modified_at
IS 'Timestamp when the encounter record was last updated';

COMMENT ON COLUMN insaights_encounter.modified_by
IS 'Identifier of the user or system that last updated the encounter record';

COMMENT ON CONSTRAINT chk_recall ON insaights_encounter
IS 'Ensures recall_date is populated only when recall_yn is TRUE';

COMMENT ON CONSTRAINT chk_pat_grp ON insaights_encounter
IS 'Ensures the encounter subject is either a single patient or a patient group, but not both';

COMMENT ON CONSTRAINT fk_encounter_subject_patient ON insaights_encounter
IS 'Foreign key linking the encounter to a patient subject';

COMMENT ON CONSTRAINT fk_encounter_subject_group ON insaights_encounter
IS 'Foreign key linking the encounter to a group subject';

COMMENT ON CONSTRAINT fk_encounter_part_of ON insaights_encounter
IS 'Foreign key linking the encounter to its parent encounter';

COMMENT ON CONSTRAINT fk_encounter_service_provider ON insaights_encounter
IS 'Foreign key linking the encounter to the service provider organisation';

--------------------------------

CREATE TABLE insaights_encounter_identifier (
    encounter_identifier_id UUID PRIMARY KEY,

    encounter_id UUID NOT NULL,
    use_code TEXT,
    type_code TEXT,
    system TEXT,
    value TEXT,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    assigner_id UUID,

    CONSTRAINT fk_encounter_identifier_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),

    CONSTRAINT fk_encounter_identifier_assigner
        FOREIGN KEY (assigner_id)
        REFERENCES insaights_organisation(org_id),
		
	CONSTRAINT uq_encounter_identifier_system_value
	UNIQUE (encounter_id, system, value)
);


COMMENT ON CONSTRAINT uq_encounter_identifier_system_value
ON insaights_encounter_identifier
IS 'Ensures that an encounter cannot have duplicate identifiers from the same issuing system; the same identifier value may be reused across different encounters or patients, consistent with FHIR Identifier semantics';

COMMENT ON TABLE insaights_encounter_identifier
IS 'FHIR Identifier element storing one or more identifiers associated with a healthcare encounter';

COMMENT ON COLUMN insaights_encounter_identifier.encounter_identifier_id
IS 'Unique identifier for the encounter identifier record';

COMMENT ON COLUMN insaights_encounter_identifier.encounter_id
IS 'Reference to the encounter to which this identifier is assigned';

COMMENT ON COLUMN insaights_encounter_identifier.use_code
IS 'Intended usage of the identifier (FHIR Identifier.use), such as usual, official, temporary, secondary, or old';

COMMENT ON COLUMN insaights_encounter_identifier.type_code
IS 'Code describing the type of encounter identifier (FHIR Identifier.type)';

COMMENT ON COLUMN insaights_encounter_identifier.system
IS 'Namespace or issuing system for the identifier (FHIR Identifier.system), such as hospital MRN or external registry';

COMMENT ON COLUMN insaights_encounter_identifier.value
IS 'Actual identifier value assigned to the encounter (FHIR Identifier.value)';

COMMENT ON COLUMN insaights_encounter_identifier.period_start
IS 'Start timestamp from which the identifier is considered valid (FHIR Identifier.period.start)';

COMMENT ON COLUMN insaights_encounter_identifier.period_end
IS 'End timestamp after which the identifier is no longer valid (FHIR Identifier.period.end)';

COMMENT ON COLUMN insaights_encounter_identifier.assigner_id
IS 'Reference to the organisation that assigned the encounter identifier (FHIR Identifier.assigner)';

COMMENT ON CONSTRAINT fk_encounter_identifier_encounter ON insaights_encounter_identifier
IS 'Foreign key linking the identifier record to the associated encounter';

COMMENT ON CONSTRAINT fk_encounter_identifier_assigner ON insaights_encounter_identifier
IS 'Foreign key linking the identifier record to the assigning organisation';

-------------------------

CREATE TABLE insaights_encounter_type (
    encounter_type_id UUID PRIMARY KEY,

    encounter_id UUID NOT NULL,
    type_code TEXT,

    CONSTRAINT fk_encounter_type_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),
		
	CONSTRAINT uq_encounter_type_per_encounter
	UNIQUE (encounter_id, type_code)
);

COMMENT ON TABLE insaights_encounter_type
IS 'FHIR Encounter.type element representing one or more classifications or categories assigned to an encounter';

COMMENT ON COLUMN insaights_encounter_type.encounter_type_id
IS 'Unique identifier for the encounter type record';

COMMENT ON COLUMN insaights_encounter_type.encounter_id
IS 'Reference to the encounter to which this type classification applies';

COMMENT ON COLUMN insaights_encounter_type.type_code
IS 'Coded encounter type (FHIR Encounter.type), such as admission, emergency, consultation, or diagnostic service';

COMMENT ON CONSTRAINT fk_encounter_type_encounter ON insaights_encounter_type
IS 'Foreign key linking the encounter type record to the associated encounter';

COMMENT ON CONSTRAINT uq_encounter_type_per_encounter ON insaights_encounter_type
IS 'Ensures that the same encounter type code is not recorded more than once for a given encounter';

-------------

CREATE TABLE insaights_encounter_service_type (
    encounter_service_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    encounter_id UUID NOT NULL,
    service_id UUID,
    service_code TEXT,

    CONSTRAINT fk_encounter_service_type_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id)
);

COMMENT ON TABLE insaights_encounter_service_type
IS 'FHIR Encounter.serviceType element representing healthcare services delivered during an encounter';

COMMENT ON COLUMN insaights_encounter_service_type.encounter_service_type_id
IS 'Unique identifier for the encounter service type record';

COMMENT ON COLUMN insaights_encounter_service_type.encounter_id
IS 'Reference to the encounter during which the service was provided';

COMMENT ON COLUMN insaights_encounter_service_type.service_id
IS 'Reference to a HealthcareService resource representing the specific service provided';

COMMENT ON COLUMN insaights_encounter_service_type.service_code
IS 'Optional standardized code identifying the type of service provided';

COMMENT ON CONSTRAINT fk_encounter_service_type_encounter ON insaights_encounter_service_type
IS 'Foreign key linking the service type record to the associated encounter';
---------------

CREATE TABLE insaights_encounter_episode_of_care (
    encounter_id UUID NOT NULL,
    visit_number INTEGER,
    episode_of_care_id UUID NOT NULL,

    CONSTRAINT pk_encounter_episode_of_care
        PRIMARY KEY (encounter_id, episode_of_care_id),

    CONSTRAINT fk_encounter_episode_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),

    CONSTRAINT fk_encounter_episode_episode
        FOREIGN KEY (episode_of_care_id)
        REFERENCES insaights_episode_of_care(id),

	CONSTRAINT chk_visit_number_non_negative
		CHECK (visit_number IS NULL OR visit_number >= 0)
);

COMMENT ON TABLE insaights_encounter_episode_of_care
IS 'Association table linking encounters to episodes of care, grouping encounters into a broader care journey or treatment plan';

COMMENT ON COLUMN insaights_encounter_episode_of_care.encounter_id
IS 'Reference to the encounter that is part of an episode of care';

COMMENT ON COLUMN insaights_encounter_episode_of_care.visit_number
IS 'Sequential visit number for the patient within the episode of care, when applicable';

COMMENT ON COLUMN insaights_encounter_episode_of_care.episode_of_care_id
IS 'Reference to the episode of care that groups related encounters for a condition or treatment plan';

COMMENT ON CONSTRAINT pk_encounter_episode_of_care ON insaights_encounter_episode_of_care
IS 'Composite primary key ensuring each encounter-to-episode association is recorded at most once';

COMMENT ON CONSTRAINT fk_encounter_episode_encounter ON insaights_encounter_episode_of_care
IS 'Foreign key linking the association record to the encounter';

COMMENT ON CONSTRAINT fk_encounter_episode_episode ON insaights_encounter_episode_of_care
IS 'Foreign key linking the association record to the episode of care';

---------

CREATE TABLE insaights_encounter_based_on (
    encounter_based_on_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    encounter_id UUID NOT NULL,
    target_type TEXT NOT NULL,
    target_id UUID NOT NULL,

    CONSTRAINT fk_encounter_based_on_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id)
);

COMMENT ON TABLE insaights_encounter_based_on
IS 'FHIR Encounter.basedOn element linking an encounter to the request resources (such as ServiceRequest, Appointment, or Referral) that triggered it';

COMMENT ON COLUMN insaights_encounter_based_on.encounter_based_on_id
IS 'Unique identifier for the encounter based-on association record';

COMMENT ON COLUMN insaights_encounter_based_on.encounter_id
IS 'Reference to the encounter that was initiated as a result of one or more request resources';

COMMENT ON COLUMN insaights_encounter_based_on.target_type
IS 'FHIR resource type of the request that triggered the encounter (e.g., Appointment, ServiceRequest, ReferralRequest)';

COMMENT ON COLUMN insaights_encounter_based_on.target_id
IS 'Identifier of the specific request resource instance that caused the encounter';

COMMENT ON CONSTRAINT fk_encounter_based_on_encounter ON insaights_encounter_based_on
IS 'Foreign key linking the based-on association record to the encounter';
------------------------

CREATE TABLE insaights_encounter_care_team (
    encounter_id UUID NOT NULL,
    care_team_id UUID NOT NULL,

    CONSTRAINT pk_encounter_care_team
        PRIMARY KEY (encounter_id, care_team_id),

    CONSTRAINT fk_encounter_care_team_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),

    CONSTRAINT fk_encounter_care_team_care_team
        FOREIGN KEY (care_team_id)
        REFERENCES insaights_care_team(id)
);

COMMENT ON TABLE insaights_encounter_care_team
IS 'Association table linking encounters to care teams involved in the encounter, representing provider groups participating in care delivery';

COMMENT ON COLUMN insaights_encounter_care_team.encounter_id
IS 'Reference to the encounter in which the care team participated';

COMMENT ON COLUMN insaights_encounter_care_team.care_team_id
IS 'Reference to the care team involved in the encounter';

COMMENT ON CONSTRAINT pk_encounter_care_team ON insaights_encounter_care_team
IS 'Composite primary key ensuring a care team is linked at most once to a given encounter';

COMMENT ON CONSTRAINT fk_encounter_care_team_encounter ON insaights_encounter_care_team
IS 'Foreign key linking the association record to the encounter';

COMMENT ON CONSTRAINT fk_encounter_care_team_care_team ON insaights_encounter_care_team
IS 'Foreign key linking the association record to the care team';

-------

CREATE TABLE insaights_encounter_participant (
    encounter_participant_id UUID PRIMARY KEY,

    encounter_id UUID NOT NULL,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,

    actor_type_code TEXT,
    actor_ref_id UUID,

    CONSTRAINT fk_encounter_participant_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),
		
	CONSTRAINT chk_participant_period
	CHECK (
    	period_start IS NULL OR
    	period_end IS NULL OR
    	period_end >= period_start
	),
	CONSTRAINT uq_encounter_participant_actor
	UNIQUE (encounter_id, actor_type_code, actor_ref_id)
);

COMMENT ON TABLE insaights_encounter_participant
IS 'FHIR Encounter.participant element representing individuals or entities involved in an encounter and their period of participation';

COMMENT ON COLUMN insaights_encounter_participant.encounter_participant_id
IS 'Unique identifier for the encounter participant record';

COMMENT ON COLUMN insaights_encounter_participant.encounter_id
IS 'Reference to the encounter in which the participant was involved';

COMMENT ON COLUMN insaights_encounter_participant.period_start
IS 'Start date and time of the participant’s involvement in the encounter';

COMMENT ON COLUMN insaights_encounter_participant.period_end
IS 'End date and time of the participant’s involvement in the encounter';

COMMENT ON COLUMN insaights_encounter_participant.actor_type_code
IS 'FHIR resource type of the participant actor, such as Patient, Practitioner, RelatedPerson, or Device';

COMMENT ON COLUMN insaights_encounter_participant.actor_ref_id
IS 'Reference identifier of the participant actor resource or application-level handle';

COMMENT ON CONSTRAINT fk_encounter_participant_encounter ON insaights_encounter_participant
IS 'Foreign key linking the participant record to the associated encounter';
------------

CREATE TABLE insaights_encounter_participant_type (
    encounter_participant_type_id UUID PRIMARY KEY,

    participant_id UUID NOT NULL,
    type_code TEXT,

    CONSTRAINT fk_participant_type_participant
        FOREIGN KEY (participant_id)
        REFERENCES insaights_encounter_participant(encounter_participant_id)
);

COMMENT ON TABLE insaights_encounter_participant_type
IS 'FHIR Encounter.participant.type element representing one or more roles or functions a participant performs during an encounter';

COMMENT ON COLUMN insaights_encounter_participant_type.encounter_participant_type_id
IS 'Unique identifier for the participant role record';

COMMENT ON COLUMN insaights_encounter_participant_type.participant_id
IS 'Reference to the encounter participant to whom this role applies';

COMMENT ON COLUMN insaights_encounter_participant_type.type_code
IS 'Role or function of the participant during the encounter (FHIR Encounter.participant.type), such as attender, consultant, or observer';

COMMENT ON CONSTRAINT fk_participant_type_participant ON insaights_encounter_participant_type
IS 'Foreign key linking the participant role record to the associated encounter participant';
--------

CREATE TABLE insaights_encounter_account (
    encounter_id UUID NOT NULL,
    account_id UUID NOT NULL,

    CONSTRAINT pk_encounter_account
        PRIMARY KEY (encounter_id, account_id),

    CONSTRAINT fk_encounter_account_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),

    CONSTRAINT fk_encounter_account_account
        FOREIGN KEY (account_id)
        REFERENCES insaights_account(id)
);
COMMENT ON TABLE insaights_encounter_account
IS 'FHIR Encounter.account association linking encounters to one or more billing accounts, supporting multiple accounts per encounter';

COMMENT ON COLUMN insaights_encounter_account.encounter_id
IS 'Reference to the encounter associated with the billing account';

COMMENT ON COLUMN insaights_encounter_account.account_id
IS 'Reference to the billing account linked to the encounter';

COMMENT ON CONSTRAINT pk_encounter_account ON insaights_encounter_account
IS 'Composite primary key ensuring an account is linked at most once to a given encounter';

COMMENT ON CONSTRAINT fk_encounter_account_encounter ON insaights_encounter_account
IS 'Foreign key linking the association record to the encounter';

COMMENT ON CONSTRAINT fk_encounter_account_account ON insaights_encounter_account
IS 'Foreign key linking the association record to the billing account';
-----------

CREATE TABLE insaights_encounter_diet_preference (
    encounter_diet_preference_id UUID PRIMARY KEY,

    encounter_id UUID NOT NULL,
    diet_code TEXT,

    CONSTRAINT fk_encounter_diet_preference_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),
		
	CONSTRAINT uq_encounter_diet_preference
	UNIQUE (encounter_id, diet_code)
);

COMMENT ON TABLE insaights_encounter_diet_preference
IS 'FHIR Encounter extension capturing patient-reported diet preferences during an encounter';

COMMENT ON COLUMN insaights_encounter_diet_preference.encounter_diet_preference_id
IS 'Unique identifier for the encounter diet preference record';

COMMENT ON COLUMN insaights_encounter_diet_preference.encounter_id
IS 'Reference to the encounter during which the diet preference was reported';

COMMENT ON COLUMN insaights_encounter_diet_preference.diet_code
IS 'Coded representation of the patient’s diet preference, such as vegetarian, vegan, or gluten-free';

COMMENT ON CONSTRAINT fk_encounter_diet_preference_encounter ON insaights_encounter_diet_preference
IS 'Foreign key linking the diet preference record to the associated encounter';

COMMENT ON CONSTRAINT uq_encounter_diet_preference ON insaights_encounter_diet_preference
IS 'Ensures the same diet preference is not recorded more than once for a given encounter';
---------

CREATE TABLE insaights_encounter_special_arrangement (
    encounter_special_arrangement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    encounter_id UUID NOT NULL,
    arrangement_code TEXT,

    CONSTRAINT fk_encounter_special_arrangement_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),
		
	CONSTRAINT uq_encounter_special_arrangement
	UNIQUE (encounter_id, arrangement_code)
);

COMMENT ON TABLE insaights_encounter_special_arrangement
IS 'FHIR Encounter extension capturing special arrangements required or provided during an encounter';

COMMENT ON COLUMN insaights_encounter_special_arrangement.encounter_special_arrangement_id
IS 'Unique identifier for the encounter special arrangement record';

COMMENT ON COLUMN insaights_encounter_special_arrangement.encounter_id
IS 'Reference to the encounter requiring the special arrangement';

COMMENT ON COLUMN insaights_encounter_special_arrangement.arrangement_code
IS 'Coded representation of a special arrangement, such as wheelchair access, translator, or stretcher';

COMMENT ON CONSTRAINT fk_encounter_special_arrangement_encounter ON insaights_encounter_special_arrangement
IS 'Foreign key linking the special arrangement record to the associated encounter';

COMMENT ON CONSTRAINT uq_encounter_special_arrangement ON insaights_encounter_special_arrangement
IS 'Ensures the same special arrangement is not recorded more than once for a given encounter';

------------------

CREATE TABLE insaights_encounter_special_courtesy (
    encounter_special_courtesy_id UUID PRIMARY KEY,

    encounter_id UUID NOT NULL,
    courtesy_code TEXT,

    CONSTRAINT fk_encounter_special_courtesy_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),
	CONSTRAINT uq_encounter_special_courtesy
	UNIQUE (encounter_id, courtesy_code)
);

COMMENT ON TABLE insaights_encounter_special_courtesy
IS 'FHIR Encounter extension capturing special courtesies or privileges applied during an encounter';

COMMENT ON COLUMN insaights_encounter_special_courtesy.encounter_special_courtesy_id
IS 'Unique identifier for the encounter special courtesy record';

COMMENT ON COLUMN insaights_encounter_special_courtesy.encounter_id
IS 'Reference to the encounter to which the special courtesy applies';

COMMENT ON COLUMN insaights_encounter_special_courtesy.courtesy_code
IS 'Coded value indicating the special courtesy or privilege (e.g., VIP, board member)';

COMMENT ON CONSTRAINT fk_encounter_special_courtesy_encounter ON insaights_encounter_special_courtesy
IS 'Foreign key linking the special courtesy record to the associated encounter';

COMMENT ON CONSTRAINT uq_encounter_special_courtesy ON insaights_encounter_special_courtesy
IS 'Ensures the same courtesy code is not recorded more than once for a given encounter';

--------
CREATE TABLE insaights_encounter_appointment (
    encounter_id UUID NOT NULL,
    appointment_id UUID NOT NULL,

    CONSTRAINT pk_encounter_appointment
        PRIMARY KEY (encounter_id, appointment_id),

    CONSTRAINT fk_encounter_appointment_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),

    CONSTRAINT fk_encounter_appointment_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES insaights_appointment(id)
);

COMMENT ON TABLE insaights_encounter_appointment
IS 'Association table linking encounters to the appointments that scheduled or initiated them';

COMMENT ON COLUMN insaights_encounter_appointment.encounter_id
IS 'Reference to the encounter that was scheduled as a result of an appointment';

COMMENT ON COLUMN insaights_encounter_appointment.appointment_id
IS 'Reference to the appointment that scheduled or is associated with the encounter';

COMMENT ON CONSTRAINT pk_encounter_appointment ON insaights_encounter_appointment
IS 'Composite primary key ensuring an appointment is linked at most once to a given encounter';

COMMENT ON CONSTRAINT fk_encounter_appointment_encounter ON insaights_encounter_appointment
IS 'Foreign key linking the association record to the encounter';

COMMENT ON CONSTRAINT fk_encounter_appointment_appointment ON insaights_encounter_appointment
IS 'Foreign key linking the association record to the appointment';

--------

CREATE TABLE insaights_encounter_virtual_service (
    encounter_virtual_service_id UUID PRIMARY KEY ,

    encounter_id UUID NOT NULL,

    channel_type_code TEXT,
    address_url TEXT,
    address_string TEXT,
    address_contact_point TEXT,
    address_extended_detail TEXT,

    max_participants INTEGER,
    session_key TEXT,
    additional_info_urls TEXT,

    CONSTRAINT fk_encounter_virtual_service_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id)
);

COMMENT ON TABLE insaights_encounter_virtual_service
IS 'FHIR Encounter.virtualService backbone element representing virtual or telehealth connection details associated with an encounter';

COMMENT ON COLUMN insaights_encounter_virtual_service.encounter_virtual_service_id
IS 'Unique identifier for the encounter virtual service record';

COMMENT ON COLUMN insaights_encounter_virtual_service.encounter_id
IS 'Reference to the encounter with which the virtual service is associated';

COMMENT ON COLUMN insaights_encounter_virtual_service.channel_type_code
IS 'Coded representation of the virtual service channel type (FHIR VirtualServiceDetail.channelType), such as video, phone, or chat';

COMMENT ON COLUMN insaights_encounter_virtual_service.address_url
IS 'Direct URI used to join the virtual session, such as a video conferencing link (FHIR VirtualServiceDetail.addressUri)';

COMMENT ON COLUMN insaights_encounter_virtual_service.address_string
IS 'Free-text description of the virtual location or connection details (FHIR VirtualServiceDetail.addressString)';

COMMENT ON COLUMN insaights_encounter_virtual_service.address_contact_point
IS 'Contact information used to connect to the virtual service, such as a phone number or email (FHIR VirtualServiceDetail.addressContactPoint)';

COMMENT ON COLUMN insaights_encounter_virtual_service.address_extended_detail
IS 'Extended or structured contact details for the virtual service, optionally stored as JSON or free text';

COMMENT ON COLUMN insaights_encounter_virtual_service.max_participants
IS 'Maximum number of participants permitted in the virtual session';

COMMENT ON COLUMN insaights_encounter_virtual_service.session_key
IS 'Access code, password, or session key required to join the virtual service';

COMMENT ON COLUMN insaights_encounter_virtual_service.additional_info_urls
IS 'Additional informational URLs associated with the virtual service (FHIR VirtualServiceDetail.additionalInfo)';

COMMENT ON CONSTRAINT fk_encounter_virtual_service_encounter ON insaights_encounter_virtual_service
IS 'Foreign key linking the virtual service record to the associated encounter';

----------

CREATE TABLE insaights_encounter_reason (
    encounter_reason_id UUID PRIMARY KEY,

    encounter_id UUID NOT NULL,

    CONSTRAINT fk_encounter_reason_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id)
);

COMMENT ON TABLE insaights_encounter_reason
IS 'FHIR Encounter.reason backbone element grouping the reason(s) associated with an encounter';

COMMENT ON COLUMN insaights_encounter_reason.encounter_reason_id
IS 'Unique identifier for the encounter reason record';

COMMENT ON COLUMN insaights_encounter_reason.encounter_id
IS 'Reference to the encounter to which this reason grouping applies';

COMMENT ON CONSTRAINT fk_encounter_reason_encounter ON insaights_encounter_reason
IS 'Foreign key linking the reason record to the associated encounter';

------
CREATE TABLE insaights_encounter_reason_use (
    encounter_reason_use_id UUID PRIMARY KEY ,

    reason_id UUID NOT NULL,
    use_code TEXT,

    CONSTRAINT fk_reason_use_reason
        FOREIGN KEY (reason_id)
        REFERENCES insaights_encounter_reason(encounter_reason_id),
		
	CONSTRAINT uq_reason_use_per_reason
	UNIQUE (reason_id, use_code)
);

COMMENT ON TABLE insaights_encounter_reason_use
IS 'FHIR Encounter.reason.use element indicating how an encounter reason is intended to be used (e.g., admission, billing, chief complaint)';

COMMENT ON COLUMN insaights_encounter_reason_use.encounter_reason_use_id
IS 'Unique identifier for the encounter reason use record';

COMMENT ON COLUMN insaights_encounter_reason_use.reason_id
IS 'Reference to the encounter reason record to which this usage applies';

COMMENT ON COLUMN insaights_encounter_reason_use.use_code
IS 'Code indicating the intended use of the reason (FHIR Encounter.reason.use)';

COMMENT ON CONSTRAINT fk_reason_use_reason ON insaights_encounter_reason_use
IS 'Foreign key linking the reason use record to the encounter reason record';

-----
CREATE TABLE insaights_encounter_reason_value (
    encounter_reason_value_id UUID PRIMARY KEY,

    reason_id UUID NOT NULL,
    value_type_code TEXT,
    value_reference_id UUID,

    CONSTRAINT fk_reason_value_reason
        FOREIGN KEY (reason_id)
        REFERENCES insaights_encounter_reason(encounter_reason_id)
);

COMMENT ON TABLE insaights_encounter_reason_value
IS 'FHIR Encounter.reason.value element capturing the reason as a reference to another clinical resource (e.g., Condition, Observation, Procedure)';

COMMENT ON COLUMN insaights_encounter_reason_value.encounter_reason_value_id
IS 'Unique identifier for the encounter reason value record';

COMMENT ON COLUMN insaights_encounter_reason_value.reason_id
IS 'Reference to the encounter reason record to which this value belongs';

COMMENT ON COLUMN insaights_encounter_reason_value.value_type_code
IS 'FHIR resource type of the referenced reason value (e.g., Condition, Observation, Procedure)';

COMMENT ON COLUMN insaights_encounter_reason_value.value_reference_id
IS 'Identifier of the referenced resource instance representing the encounter reason';

COMMENT ON CONSTRAINT fk_reason_value_reason ON insaights_encounter_reason_value
IS 'Foreign key linking the reason value record to the encounter reason record';

-------

CREATE TABLE insaights_encounter_diagnosis (
    encounter_diagnosis_id UUID PRIMARY KEY ,

    encounter_id UUID NOT NULL,

    CONSTRAINT fk_encounter_diagnosis_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id)
);

COMMENT ON TABLE insaights_encounter_diagnosis
IS 'FHIR Encounter.diagnosis backbone element grouping diagnosis information associated with an encounter';

COMMENT ON COLUMN insaights_encounter_diagnosis.encounter_diagnosis_id
IS 'Unique identifier for the encounter diagnosis record';

COMMENT ON COLUMN insaights_encounter_diagnosis.encounter_id
IS 'Reference to the encounter to which this diagnosis entry belongs';

COMMENT ON CONSTRAINT fk_encounter_diagnosis_encounter ON insaights_encounter_diagnosis
IS 'Foreign key linking the diagnosis record to the associated encounter';

------

CREATE TABLE insaights_encounter_diagnosis_condition (
    encounter_diagnosis_condition_id UUID PRIMARY KEY,

    diagnosis_id UUID NOT NULL,
    condition_id UUID,
    value_code TEXT,

    CONSTRAINT fk_diag_condition_diagnosis
        FOREIGN KEY (diagnosis_id)
        REFERENCES insaights_encounter_diagnosis(encounter_diagnosis_id),

    CONSTRAINT fk_diag_condition_condition
        FOREIGN KEY (condition_id)
        REFERENCES insaights_condition(id),
		
	CONSTRAINT uq_diag_condition_per_diagnosis
	UNIQUE (diagnosis_id, condition_id, value_code)
);

COMMENT ON TABLE insaights_encounter_diagnosis_condition
IS 'FHIR Encounter.diagnosis.condition element linking a diagnosis entry to one or more conditions or coded concepts';

COMMENT ON COLUMN insaights_encounter_diagnosis_condition.encounter_diagnosis_condition_id
IS 'Unique identifier for the diagnosis condition record';

COMMENT ON COLUMN insaights_encounter_diagnosis_condition.diagnosis_id
IS 'Reference to the parent encounter diagnosis record to which this condition entry belongs';

COMMENT ON COLUMN insaights_encounter_diagnosis_condition.condition_id
IS 'Reference to a Condition resource associated with the diagnosis (FHIR Reference(Condition))';

COMMENT ON COLUMN insaights_encounter_diagnosis_condition.value_code
IS 'Optional coded representation of the diagnosis when not represented as a Condition reference';

COMMENT ON CONSTRAINT fk_diag_condition_diagnosis ON insaights_encounter_diagnosis_condition
IS 'Foreign key linking the condition entry to the parent encounter diagnosis record';

COMMENT ON CONSTRAINT fk_diag_condition_condition ON insaights_encounter_diagnosis_condition
IS 'Foreign key linking the condition entry to the referenced Condition resource';

COMMENT ON CONSTRAINT uq_diag_condition_per_diagnosis ON insaights_encounter_diagnosis_condition
IS 'Ensures the same diagnosis condition association is not recorded more than once for a given diagnosis entry';
-----
CREATE TABLE insaights_encounter_diagnosis_use (
    encounter_diagnosis_use_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    diagnosis_id UUID NOT NULL,
    use_code TEXT,

    CONSTRAINT fk_diagnosis_use_diagnosis
        FOREIGN KEY (diagnosis_id)
        REFERENCES insaights_encounter_diagnosis(encounter_diagnosis_id),

	 CONSTRAINT uq_diagnosis_use_per_diagnosis
	UNIQUE (diagnosis_id, use_code)
);

COMMENT ON TABLE insaights_encounter_diagnosis_use
IS 'FHIR Encounter.diagnosis.use element indicating the role a diagnosis plays within an encounter (e.g., admission, billing, discharge)';

COMMENT ON COLUMN insaights_encounter_diagnosis_use.encounter_diagnosis_use_id
IS 'Unique identifier for the diagnosis use record';

COMMENT ON COLUMN insaights_encounter_diagnosis_use.diagnosis_id
IS 'Reference to the encounter diagnosis record to which this usage role applies';

COMMENT ON COLUMN insaights_encounter_diagnosis_use.use_code
IS 'Code indicating the role of the diagnosis within the encounter (FHIR Encounter.diagnosis.use)';

COMMENT ON CONSTRAINT fk_diagnosis_use_diagnosis ON insaights_encounter_diagnosis_use
IS 'Foreign key linking the diagnosis use record to the parent encounter diagnosis record';

COMMENT ON CONSTRAINT uq_diagnosis_use_per_diagnosis ON insaights_encounter_diagnosis_use
IS 'Ensures the same diagnosis role is not recorded more than once for a given diagnosis entry';
-------

CREATE TABLE insaights_encounter_admission (
    encounter_id UUID PRIMARY KEY,

    pre_admission_identifier TEXT,
    admission_number TEXT,

    origin_type TEXT,
    origin_id UUID,
    destination_type TEXT,
    destination_id UUID,

    admit_source_code TEXT,
    re_admission_code TEXT,
    discharge_disposition_code TEXT,

    admitting_practitioner_id UUID,
    assigned_bed_type_code TEXT,
    assigned_bed_class_code TEXT,
    bed_allocation_datetime TIMESTAMPTZ,
    room_tel_num TEXT,
    discharge_unit_code TEXT,
    disch_practitioner_id UUID,
    disp_auth_practitioner_id UUID,

    CONSTRAINT fk_encounter_admission_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id)
);

COMMENT ON TABLE insaights_encounter_admission
IS 'Admission and discharge details associated with an encounter, including origin, destination, bed allocation, and responsible practitioners';

COMMENT ON COLUMN insaights_encounter_admission.encounter_id
IS 'Reference to the encounter for which admission details are recorded; also serves as the primary key (one admission record per encounter)';

COMMENT ON COLUMN insaights_encounter_admission.pre_admission_identifier
IS 'Identifier used prior to formal admission, when available';

COMMENT ON COLUMN insaights_encounter_admission.admission_number
IS 'Hospital-generated admission number for the encounter';

COMMENT ON COLUMN insaights_encounter_admission.origin_type
IS 'Resource type representing the patient origin prior to admission (e.g., Location or Organisation)';

COMMENT ON COLUMN insaights_encounter_admission.origin_id
IS 'Identifier of the origin resource from which the patient came';

COMMENT ON COLUMN insaights_encounter_admission.destination_type
IS 'Resource type representing the destination after discharge (e.g., Location or Organisation)';

COMMENT ON COLUMN insaights_encounter_admission.destination_id
IS 'Identifier of the destination resource to which the patient was discharged';

COMMENT ON COLUMN insaights_encounter_admission.admit_source_code
IS 'Code indicating the source or reason for admission (e.g., referral, transfer)';

COMMENT ON COLUMN insaights_encounter_admission.re_admission_code
IS 'Code indicating whether this admission is a readmission';

COMMENT ON COLUMN insaights_encounter_admission.discharge_disposition_code
IS 'Code indicating discharge disposition (e.g., home, transfer, deceased)';

COMMENT ON COLUMN insaights_encounter_admission.admitting_practitioner_id
IS 'Reference to the practitioner responsible for admitting the patient';

COMMENT ON COLUMN insaights_encounter_admission.assigned_bed_type_code
IS 'Type of bed allocated during admission (facility-specific)';

COMMENT ON COLUMN insaights_encounter_admission.assigned_bed_class_code
IS 'Bed class indicating service level (e.g., general, semi-private, VIP, ICU)';

COMMENT ON COLUMN insaights_encounter_admission.bed_allocation_datetime
IS 'Timestamp indicating when bed allocation occurred';

COMMENT ON COLUMN insaights_encounter_admission.room_tel_num
IS 'Telephone number associated with the patient room, when available';

COMMENT ON COLUMN insaights_encounter_admission.discharge_unit_code
IS 'Ward or unit from which the patient was discharged';

COMMENT ON COLUMN insaights_encounter_admission.disch_practitioner_id
IS 'Reference to the practitioner who discharged the patient';

COMMENT ON COLUMN insaights_encounter_admission.disp_auth_practitioner_id
IS 'Reference to the practitioner who authorised discharge';

COMMENT ON CONSTRAINT fk_encounter_admission_encounter ON insaights_encounter_admission
IS 'Foreign key linking admission details to the associated encounter';

-------
CREATE TABLE insaights_encounter_location (
    encounter_location_id UUID PRIMARY KEY,

    encounter_id UUID NOT NULL,
    location_id UUID NOT NULL,

    status_code TEXT,
    form_code TEXT,

    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,

    CONSTRAINT fk_encounter_location_encounter
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id),

    CONSTRAINT fk_encounter_location_location
        FOREIGN KEY (location_id)
        REFERENCES insaights_location(id),
	CONSTRAINT uq_encounter_location_period
	UNIQUE (encounter_id, location_id, period_start)
);

COMMENT ON TABLE insaights_encounter_location
IS 'Tracks patient location(s) during an encounter, including status, location form, and time period';

COMMENT ON COLUMN insaights_encounter_location.encounter_location_id
IS 'Unique identifier for the encounter location record';

COMMENT ON COLUMN insaights_encounter_location.encounter_id
IS 'Reference to the encounter during which the patient occupied the location';

COMMENT ON COLUMN insaights_encounter_location.location_id
IS 'Reference to the location resource (e.g., room, ward, ICU)';

COMMENT ON COLUMN insaights_encounter_location.status_code
IS 'Status of the patient/location assignment (e.g., planned, active, completed)';

COMMENT ON COLUMN insaights_encounter_location.form_code
IS 'Type or form of the location (e.g., room, ward, ICU)';

COMMENT ON COLUMN insaights_encounter_location.period_start
IS 'Start timestamp when the patient was at this location';

COMMENT ON COLUMN insaights_encounter_location.period_end
IS 'End timestamp when the patient left this location';

COMMENT ON CONSTRAINT fk_encounter_location_encounter ON insaights_encounter_location
IS 'Foreign key linking the location record to the associated encounter';

COMMENT ON CONSTRAINT fk_encounter_location_location ON insaights_encounter_location
IS 'Foreign key linking the location record to the referenced location resource';

COMMENT ON CONSTRAINT uq_encounter_location_period ON insaights_encounter_location
IS 'Helps prevent duplicate location assignments for the same encounter and start time';

------
CREATE TABLE insaights_encounter_police_report (
    encounter_id UUID PRIMARY KEY,

    pol_rep_no TEXT,
    pol_stn_id UUID,
    pol_id UUID,
    informed_to TEXT,
    informed_name TEXT,
    informed_date_time TIMESTAMPTZ,
    post_mortem_req BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_encounter_police_report
        FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(encounter_id)
);

COMMENT ON TABLE insaights_encounter_police_report
IS 'Police report details linked to an encounter, including station/officer details, informed party, and post-mortem request indicator';

COMMENT ON COLUMN insaights_encounter_police_report.encounter_id
IS 'Reference to the encounter associated with this police report; also serves as the primary key (one police report record per encounter)';

COMMENT ON COLUMN insaights_encounter_police_report.pol_rep_no
IS 'Police report number associated with the incident';

COMMENT ON COLUMN insaights_encounter_police_report.pol_stn_id
IS 'Identifier of the police station associated with the report';

COMMENT ON COLUMN insaights_encounter_police_report.pol_id
IS 'Identifier of the police officer handling the case';

COMMENT ON COLUMN insaights_encounter_police_report.informed_to
IS 'Identifier or role describing who was informed about the report';

COMMENT ON COLUMN insaights_encounter_police_report.informed_name
IS 'Name of the person informed about the report';

COMMENT ON COLUMN insaights_encounter_police_report.informed_date_time
IS 'Timestamp when the report was communicated to the informed party';

COMMENT ON COLUMN insaights_encounter_police_report.post_mortem_req
IS 'Indicates whether a post-mortem was requested';

COMMENT ON CONSTRAINT fk_encounter_police_report ON insaights_encounter_police_report
IS 'Foreign key linking the police report record to the associated encounter';

---48 tables---

