-- Encounter table --
-- An interaction during which services are provided to the patient
-- a specific interaction, like a hospital visit, consultation, or surgery.
use insaights_db;

CREATE TABLE codeable_concept ( -- like look up table, centralised or decentralised
  concept_type VARCHAR(50) NOT NULL,        -- encounter status,Act-priority      
  `code` VARCHAR(32) NOT NULL,              -- planned,in-progress,Asap  
  `system` VARCHAR(255),                    -- 	http://hl7.org/fhir/encounter-status
  display VARCHAR(255),                     -- Planned, In Progress
  `text` VARCHAR(255),                   -- Optional free text if provided
  PRIMARY KEY (concept_type, `code`)       -- Composite primary key
);

CREATE TABLE `group` ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY
);

CREATE TABLE episode_of_care ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY
);

CREATE TABLE care_team ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY
);

CREATE TABLE appointment ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY
);

CREATE TABLE `account` ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY
);

CREATE TABLE location ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY
);







CREATE TABLE encounter (
    id                      VARCHAR(64) NOT NULL PRIMARY KEY, -- uuid
    `status`                VARCHAR(20) NOT NULL, -- status of the vist (planned,in-progress	,on-hold etc)
    priority_code           VARCHAR(32), -- like A -for ASAP,R-routine service
    
    subject_patient_id      VARCHAR(64), -- The patient or group related to this encounter fk of patient resource
    subject_group_id        VARCHAR(64),

    subject_status_code     VARCHAR(32), -- patient status like arrived,triaged,on-leave

    part_of_encounter_id    VARCHAR(64),-- Another Encounter this encounter is part of,connected to parent encounter
    service_provider_org_id VARCHAR(64),

    actual_start            DATETIME, -- The actual start and end time of the encounter
    actual_end              DATETIME,-- some times planned and actual schedule may differ
    planned_start           DATETIME,-- The planned start date/time (or admission date) of the encounter
    planned_end             DATETIME,

    length_quantity         INT, --  how long the encounter lasted 
    length_unit             VARCHAR(20), -- unit like minu or hrs
    
    triage_temp				FLOAT, -- Temperature at triage (C)
    triage_hr				FLOAT, -- Heart rate at triage (bpm)
    triage_rr				FLOAT, -- Respiratory rate at triage (breaths per min.)
    triage_spo2				FLOAT, -- Oxygen saturation at triage (%)
    triage_sbp				FLOAT, -- Systolic blood pressure at triage (mmHg)
    triage_dbp				FlOAT, -- Diastolic blood pressure at triage (mmHg)
    triage_acuity			VARCHAR(32), -- Emergency Severity Index (ESI) at triage (1-5)
    
	class_code      		VARCHAR(32),  -- Classification of patient encounter context - e.g. Inpatient, outpatient,virtual,home health

    CONSTRAINT fk_encounter_subject_patient FOREIGN KEY (subject_patient_id) REFERENCES patient(id),
    CONSTRAINT fk_encounter_subject_group FOREIGN KEY (subject_group_id) REFERENCES `group`(id),
    CONSTRAINT fk_encounter_part_of FOREIGN KEY (part_of_encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_service_provider FOREIGN KEY (service_provider_org_id) REFERENCES organisation(id)
);

CREATE TABLE encounter_identifier ( -- Medical record number ,insurance
    id                 	INT AUTO_INCREMENT PRIMARY KEY,
    encounter_id       	VARCHAR(64) NOT NULL,
    `use`               VARCHAR(32), -- ('usual', 'official', 'temp', 'secondary', 'old'),
    type_code          	VARCHAR(32),
    `system`            VARCHAR(255),
    `value`             VARCHAR(255),
    period_start       	DATETIME,
    period_end         	DATETIME,
    assigner_id 		VARCHAR(64),

    CONSTRAINT fk_encounter_identifier_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_identifier_assigner FOREIGN KEY (assigner_id) REFERENCES organisation(id)
);

CREATE TABLE encounter_type ( -- Multiple services were provided during that one visit.
    id        VARCHAR(64) NOT NULL PRIMARY KEY, -- A patient has an encounter that involves both a cardiology consultation and a diagnostic imaging session.
    encounter_id VARCHAR(64) NOT NULL,
    `code`      VARCHAR(50),

    CONSTRAINT fk_encounter_type_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);

CREATE TABLE encounter_service_type ( -- Describes specific healthcare services provided during the encounter, Cardiology, Radiology, Pediatrics
    id           VARCHAR(64) NOT NULL PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    service_id   VARCHAR(64),
    `code`         VARCHAR(50),

    CONSTRAINT fk_encounter_service_type_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);

-- a period of treatment or condition management.
CREATE TABLE encounter_episode_of_care ( -- This hospital visit (encounter) is part of a longer care journey (episode). reference
    encounter_id       VARCHAR(64) NOT NULL,
    episode_of_care_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (encounter_id, episode_of_care_id),

    CONSTRAINT fk_encounter_episode_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_episode_episode FOREIGN KEY (episode_of_care_id) REFERENCES episode_of_care(id)
);

CREATE TABLE encounter_based_on ( -- Why did this encounter happen? ServiceRequest
    id           VARCHAR(64) PRIMARY KEY, -- One Encounter can be based on multiple requests (e.g., lab request + appointment + referral
    encounter_id VARCHAR(64) NOT NULL,
    target_type  VARCHAR(64) NOT NULL,
    target_id    VARCHAR(64) NOT NULL,

    CONSTRAINT fk_encounter_based_on_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);

CREATE TABLE encounter_care_team ( -- Represents groups of healthcare providers involved in this encounter.
    encounter_id VARCHAR(64) NOT NULL,
    care_team_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (encounter_id, care_team_id),

    CONSTRAINT fk_encounter_care_team_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_care_team_team FOREIGN KEY (care_team_id) REFERENCES care_team(id)
);

CREATE TABLE encounter_participant ( -- participant defines who (or what) took part during the encounter, their roles, and when.
    id                  VARCHAR(64) NOT NULL PRIMARY KEY,
    encounter_id        VARCHAR(64) NOT NULL,
    type_code           VARCHAR(32),
    period_start        DATETIME,
    period_end          DATETIME,
    actor_patient_id    VARCHAR(64),
    actor_practitioner_id VARCHAR(64),

    CONSTRAINT fk_encounter_participant_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_participant_patient FOREIGN KEY (actor_patient_id) REFERENCES patient(id),
    CONSTRAINT fk_encounter_participant_practitioner FOREIGN KEY (actor_practitioner_id) REFERENCES practitioner(id)
);

CREATE TABLE encounter_appointment ( -- The appointment that scheduled this encounter
    encounter_id  VARCHAR(64) NOT NULL,
    appointment_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (encounter_id, appointment_id),

    CONSTRAINT fk_encounter_appointment_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_appointment_appointment FOREIGN KEY (appointment_id) REFERENCES appointment(id)
);

CREATE TABLE encounter_virtual_service ( -- vitrual connection
    id                       INT AUTO_INCREMENT PRIMARY KEY,
    encounter_id             VARCHAR(64) NOT NULL,
    
    channel_type_code        VARCHAR(32),    -- Coding.system + Coding.code for channelType
    
    address_url              VARCHAR(255),   -- addressUri (e.g. "https://zoom.us/j/123456789")
    address_string           VARCHAR(255),   -- addressString (e.g. "Meeting Room 1")
    address_contact_point    VARCHAR(255),   -- could store a phone number or email as string
    address_extended_detail  TEXT,           -- JSON or text for extended contact details
    
    max_participants         INT,            -- maximum number of participants allowed
    session_key              VARCHAR(100),   -- key or password required for session
    
    -- Could store multiple additional info URLs in a separate table or JSON
    additional_info_urls     TEXT,           -- JSON array or comma-separated URLs
    
    CONSTRAINT fk_encounter_virtual_service_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);


CREATE TABLE encounter_reason ( -- 	The list of medical reasons that are expected to be addressed during the episode of care
    id          VARCHAR(64) NOT NULL PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    use_code    VARCHAR(32),

    CONSTRAINT fk_encounter_reason_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);

CREATE TABLE encounter_diagnosis ( -- The list of diagnosis relevant to this encounter
    id           VARCHAR(64) NOT NULL PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    condition_id VARCHAR(64),
    use_code     VARCHAR(32),

    CONSTRAINT fk_encounter_diagnosis_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);

CREATE TABLE encounter_account ( -- the billing accounts associated with the encounter.,separate accounts for paying like hospital and lab
    encounter_id VARCHAR(64) NOT NULL,
    account_id   VARCHAR(64) NOT NULL,
    PRIMARY KEY (encounter_id, account_id),

    CONSTRAINT fk_encounter_account_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_account_account FOREIGN KEY (account_id) REFERENCES `account`(id)
);

CREATE TABLE encounter_diet_preference ( -- 	Diet preferences reported by the patient like vegetarian
    id           	  VARCHAR(64) NOT NULL PRIMARY KEY,
    encounter_id 	  VARCHAR(64) NOT NULL,
    diet_code         VARCHAR(32),

    CONSTRAINT fk_encounter_diet_preference_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);

CREATE TABLE encounter_special_arrangement ( -- Wheelchair, translator, stretcher, etc
    id           VARCHAR(64) NOT NULL PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    arrangement_code         VARCHAR(32),

    CONSTRAINT fk_encounter_special_arrangement_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);

CREATE TABLE encounter_special_courtesy ( -- Special courtesies (VIP, board member)
    id           VARCHAR(64) NOT NULL PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    courtesy_code         VARCHAR(50),

    CONSTRAINT fk_encounter_special_courtesy_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id)
);

CREATE TABLE encounter_admission (-- admission-related info when a patient is formally admitted to a facility, -- since it is a backbone element
    encounter_id                   VARCHAR(64) NOT NULL PRIMARY KEY,
    pre_admission_identifier       VARCHAR(64),
    origin_location_id             VARCHAR(64),
    admit_source_code              VARCHAR(32),
    re_admission_code             VARCHAR(32),
    discharge_disposition_code     VARCHAR(32),
    destination_location_id        VARCHAR(64),

    CONSTRAINT fk_encounter_admission_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_admission_origin FOREIGN KEY (origin_location_id) REFERENCES location(id),
    CONSTRAINT fk_encounter_admission_destination FOREIGN KEY (destination_location_id) REFERENCES location(id)
);

CREATE TABLE encounter_location ( -- tracks where a patient was during the encounter, including details like status, physical form, and time period.
    id            VARCHAR(64) NOT NULL PRIMARY KEY,
    encounter_id  VARCHAR(64) NOT NULL,
    location_id   VARCHAR(64) NOT NULL,
    `status`        VARCHAR(20),
    form_code     VARCHAR(32),
    
    period_start  DATETIME,
    period_end    DATETIME,

    CONSTRAINT fk_encounter_location_encounter FOREIGN KEY (encounter_id) REFERENCES encounter(id),
    CONSTRAINT fk_encounter_location_location FOREIGN KEY (location_id) REFERENCES location(id)
);
