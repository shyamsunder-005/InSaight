-- Encounter table -- 
-- An interaction during which services are provided to the patient -- a specific interaction, like a hospital visit, consultation, or surgery. 

-- implementing using db based comments 24 tables + 10tables for refernce fks

CREATE TABLE insaights_group ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY );

CREATE TABLE insaights_condition ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY );

CREATE TABLE insaights_episode_of_care ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY );

CREATE TABLE insaights_care_team ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY );

CREATE TABLE insaights_appointment ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY );

CREATE TABLE insaights_account ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY );

CREATE TABLE insaights_location ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY );

 CREATE TABLE insaights_healthcare_service ( --  for reference only not permanent
	id  VARCHAR(64) PRIMARY KEY );
   
-- ----------------------------------------------------------------------------
CREATE TABLE insaights_encounter (
	id 		VARCHAR(64) PRIMARY KEY NOT NULL COMMENT 'Unique indentifier - hospital generated or..', 
    
    status_code             VARCHAR(20) NOT NULL COMMENT 'Status of the visit: planned, in-progress, on-hold, etc.',
    status_set_on_date    	DATETIME COMMENT 'Date/time when this status was assigned',
	status_set_by_user_id 	VARCHAR(64) COMMENT 'FK to staff who assigned the status',
	status_reason         	VARCHAR(255) COMMENT 'Reason why the status was updated (e.g., patient left early, admitted late)',
	adt_status             	VARCHAR(32) COMMENT 'Custom administrative status (e.g., check-in, pre-admit, discharged)',
    priority_code           VARCHAR(32) COMMENT 'Encounter priority (e.g., A-ASAP, R-Routine)', 
    
    subject_patient_id      VARCHAR(64) COMMENT 'FK to the patient involved in this encounter', 
    subject_group_id        VARCHAR(64) COMMENT 'FK to the patient group involved, if applicable',
    
    subject_status_code     VARCHAR(32) COMMENT 'Patient status during encounter (arrived, triaged, on-leave)',
    part_of_encounter_id    VARCHAR(64) COMMENT 'FK to a parent encounter, if this is a sub-encounter',
    service_provider_org_id VARCHAR(64) COMMENT 'FK to the organization providing the service',
    
	planned_start           DATETIME COMMENT 'Scheduled start of the encounter',-- The planned start date/time (or admission date) of the encounter
    planned_end             DATETIME COMMENT 'Scheduled end of the encounter',
    actual_start            DATETIME COMMENT 'Actual start date/time of the encounter',
    actual_end              DATETIME COMMENT 'Actual end date/time of the encounter',-- some times planned and actual schedule may differ
    
    length_quantity         DECIMAL(6,2) COMMENT 'Duration of the encounter', 
    length_unit             VARCHAR(10) COMMENT 'Unit of duration (min, hr, etc.)', -- unit like minu or hrs UCUM codes
    class_code              VARCHAR(32) COMMENT 'Type/classification of encounter (inpatient, outpatient, virtual, home health)',

	recall_yn               BOOLEAN COMMENT 'Indicates if a follow-up is required', -- follow up true or false
    recall_date             DATE COMMENT 'Follow-up date if recall_yn is true',    -- if yes which date
    
    patient_type_code 		VARCHAR(32) COMMENT 'whether the patient is new or returning or general patient',
    fiscal_year 			VARCHAR(16) COMMENT 'Fiscal or reporting year for the encounter (e.g., 2024-2025)',
    fiscal_period 			VARCHAR(16) COMMENT 'Reporting month, quarter, or period for the encounter (e.g., Jan, Q1, FY24Q1)',
	shift_id 				VARCHAR(32) COMMENT 'Shift during which the encounter occurred',
	backdated_yn 			BOOLEAN NOT NULL COMMENT 'Indicates whether the encounter is backdated: TRUE or FALSE',
	brought_dead  			BOOLEAN NOT NULL COMMENT 'Patient brought dead flag (1 = Yes, 0 = No)',
    priority_zone_code 		VARCHAR(32) COMMENT 'Emergency triage or priority zone code assigned to the patient during this encounter, red,green, blue',
    security_level_code 	VARCHAR(32) DEFAULT 'NORMAL'COMMENT 'Access restriction level (NORMAL, RESTRICTED, CONFIDENTIAL, HIGHLY_CONFIDENTIAL)',
    protection_ind 			BOOLEAN DEFAULT FALSE COMMENT 'Boolean protection indicator; TRUE = additional protection required',

    -- audit fields
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(64) NOT NULL,
    modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	modified_by VARCHAR(64) NOT NULL DEFAULT 'SYSTEM',
    
   CONSTRAINT chk_recall
	   CHECK (
		 (recall_yn = TRUE AND recall_date IS NOT NULL) OR
		 (recall_yn = FALSE AND recall_date IS NULL)
		),
    
    CONSTRAINT chk_pat_grp
		CHECK (
		(subject_patient_id IS NOT NULL AND subject_group_id IS NULL) OR
		(subject_patient_id IS NULL AND subject_group_id IS NOT NULL)
		), -- ensures either the encounter is for a single patient, or for a patient group, never both.
    
    CONSTRAINT fk_encounter_subject_patient FOREIGN KEY (subject_patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_encounter_subject_group FOREIGN KEY (subject_group_id) REFERENCES insaights_group(id),
    CONSTRAINT fk_encounter_part_of FOREIGN KEY (part_of_encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_service_provider FOREIGN KEY (service_provider_org_id) REFERENCES insaights_organisation(id)
) COMMENT = 'An interaction between a patient and the healthcare system';

CREATE TABLE insaights_encounter_identifier (
    id 		VARCHAR(64) PRIMARY KEY DEFAULT (UUID()) COMMENT 'Unique identifier for the encounter identifier record',
    
    encounter_id 				VARCHAR(64) NOT NULL COMMENT 'FK to the encounter this identifier belongs to',
    use_code 					VARCHAR(32) COMMENT 'Purpose of this identifier (usual, official, temp, secondary, old)',
    type_code 					VARCHAR(32) COMMENT 'Code indicating the type of identifier',
    `system` 					VARCHAR(255) COMMENT 'The identifier system or namespace (e.g., hospital MRN, external registry)',
    `value` 					VARCHAR(255) COMMENT 'The identifier value assigned to the encounter',
    period_start 				DATETIME COMMENT 'Start date/time for which this identifier is valid',
    period_end 					DATETIME COMMENT 'End date/time for which this identifier is valid',
    assigner_id 				VARCHAR(64) COMMENT 'FK to the organization that assigned this identifier',
    
    CONSTRAINT fk_encounter_identifier_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_identifier_assigner FOREIGN KEY (assigner_id) REFERENCES insaights_organisation(id)
) COMMENT = 'Stores one or more identifiers for each encounter';

CREATE TABLE insaights_encounter_type (
    id 		VARCHAR(64) PRIMARY KEY DEFAULT (UUID()) COMMENT 'Unique identifier for the encounter type record',
    
    encounter_id 				VARCHAR(64) NOT NULL COMMENT 'FK to the encounter during which this type is recorded',
    type_code 					VARCHAR(32) COMMENT 'Standardized code representing the encounter type (FHIR Encounter.type), e.g., ADMS, EMER, BD/BM-clin',
    
    CONSTRAINT fk_encounter_type_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT = 'Stores the specific types or categories of an encounter, allowing multiple types per encounter (e.g., cardiology consultation and diagnostic imaging in the same visit)';


CREATE TABLE insaights_encounter_service_type (
    id 		VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for the encounter-service type record',
    
    encounter_id 				VARCHAR(64) NOT NULL COMMENT 'FK to the encounter during which this service was provided',
    service_id   				VARCHAR(64) COMMENT 'FK to the HealthcareService resource representing the specific service provided (e.g., Cardiology, Radiology, Pediatrics)',
    service_code 				VARCHAR(32) COMMENT 'Optional standardized code representing the type of service provided like card',
    
    CONSTRAINT fk_encounter_service_type_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT = 'Tracks the specific healthcare services delivered during an encounter, linking each encounter to one or more service types';

CREATE TABLE insaights_encounter_episode_of_care (
    encounter_id VARCHAR(64) NOT NULL COMMENT 'FK to the encounter that is part of an episode of care',
	visit_number         		INT COMMENT 'Sequential visit number for the patient under the episode of care',
    episode_of_care_id 			VARCHAR(64) NOT NULL COMMENT 'FK to the episode of care grouping this encounter with others for a specific condition or treatment plan',
    
    PRIMARY KEY (encounter_id, episode_of_care_id),
    CONSTRAINT fk_encounter_episode_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_episode_episode FOREIGN KEY (episode_of_care_id) REFERENCES insaights_episode_of_care(id)
) COMMENT = 'Associates individual encounters with their corresponding episode of care, representing a longer care journey or treatment plan for the patient';

CREATE TABLE insaights_encounter_based_on (
    id VARCHAR(64) PRIMARY KEY COMMENT 'Unique identifier for this record; allows multiple requests to be linked to one encounter',
    
    encounter_id 				VARCHAR(64) NOT NULL COMMENT 'FK to insaights_encounter; identifies the encounter this record belongs to',
    target_type 				VARCHAR(64) NOT NULL COMMENT 'FHIR resource type of the request that triggered the encounter (e.g., Appointment, ServiceRequest, ReferralRequest)',
    target_id 					VARCHAR(64) NOT NULL COMMENT 'ID of the specific resource instance (Appointment ID, ServiceRequest ID, etc.)',
    
    CONSTRAINT fk_encounter_based_on_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT='Links an Encounter to the requests (ServiceRequest, Appointment, Referral, etc.) that caused it to occur';


CREATE TABLE insaights_encounter_care_team (
    encounter_id 				VARCHAR(64) NOT NULL COMMENT 'FK to insaights_encounter; identifies the encounter',
    care_team_id 				VARCHAR(64) NOT NULL COMMENT 'FK to insaights_care_team; identifies the care team involved',
    
    PRIMARY KEY (encounter_id, care_team_id) COMMENT 'Composite PK ensuring uniqueness of care team participation in an encounter',
    CONSTRAINT fk_encounter_care_team_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT='Associative table linking encounters with care teams, representing healthcare providers/groups involved in the encounter';

CREATE TABLE insaights_encounter_participant (
    id	VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this participant entry (UUID or FHIR id)',
    
    encounter_id        		VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; the encounter this participant is associated with',
    period_start        		DATETIME COMMENT 'Start time of the participant’s involvement during the encounter',
    period_end          		DATETIME COMMENT 'End time of the participant’s involvement during the encounter',
   
    actor_type_code     		VARCHAR(32) COMMENT 'Type of the actor (Patient, Practitioner, related person, etc.)',
    actor_ref_id  				VARCHAR(64) COMMENT 'Reference to the participant actor (FK to Patient, Practitioner, or other relevant resource) or handle in application lv',
    
    CONSTRAINT fk_encounter_participant_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT = 'FHIR Encounter.participant: Participants involved in an encounter, their roles, actor type, and period of involvement';

CREATE TABLE insaights_encounter_participant_type (
    id	VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this participant role entry',
    
    participant_id   		VARCHAR(64) NOT NULL COMMENT 'FK to participant',
    type_code        		VARCHAR(32) COMMENT 'Role of the participant in the encounter (e.g., attender, consultant, observer)',
    
    CONSTRAINT fk_participant_type_participant FOREIGN KEY (participant_id) REFERENCES insaights_encounter_participant(id)
) COMMENT='FHIR Encounter.participant.type: Roles or functions the participant has in the encounter';

CREATE TABLE insaights_encounter_account (
    encounter_id 			VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; the encounter associated with this billing account',
    account_id   			VARCHAR(64) NOT NULL COMMENT 'FK to Account; the billing account linked to this encounter',
    
    PRIMARY KEY (encounter_id, account_id),
    CONSTRAINT fk_encounter_account_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_account_account   FOREIGN KEY (account_id)   REFERENCES insaights_account(id)
) COMMENT = 'Billing accounts linked to an encounter. Supports multiple accounts per encounter (e.g., hospital charges, lab charges) in line with FHIR Encounter.account';


CREATE TABLE insaights_encounter_diet_preference (
    id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for the diet preference entry (UUID or FHIR id)',
    
    encounter_id 			VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; the encounter during which this diet preference was reported',
    diet_code    			VARCHAR(32) COMMENT 'Code representing the patient’s diet preference (e.g., vegetarian, vegan, gluten-free)',
    
    CONSTRAINT fk_encounter_diet_preference_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT = 'Patient-reported diet preferences during an encounter (FHIR: Encounter.extension[dietPreference])';

CREATE TABLE insaights_encounter_special_arrangement (
    id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this special arrangement entry',
    
    encounter_id     		VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; the encounter requiring this special arrangement',
    arrangement_code 		VARCHAR(32) COMMENT 'Code for special arrangements requested or provided (e.g., wheelchair, translator, stretcher)',
    
    CONSTRAINT fk_encounter_special_arrangement_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT = 'Special arrangements needed during an encounter (FHIR: Encounter.extension[specialArrangement])';

CREATE TABLE insaights_encounter_special_courtesy (
    id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this courtesy entry',
    
    encounter_id   			VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; the encounter where the courtesy applies',
    courtesy_code  			VARCHAR(50) COMMENT 'Code indicating special courtesy or privilege (e.g., VIP, board member)',
    
    CONSTRAINT fk_encounter_special_courtesy_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT = 'Special courtesies granted during an encounter (FHIR: Encounter.extension[specialCourtesy])';


CREATE TABLE insaights_encounter_appointment ( 
    encounter_id   			VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; the encounter that was scheduled by this appointment',
    appointment_id 			VARCHAR(64) NOT NULL COMMENT 'FK to Appointment; the appointment that scheduled this encounter',
    
    PRIMARY KEY (encounter_id, appointment_id),
    
    CONSTRAINT fk_encounter_appointment_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_appointment_appointment FOREIGN KEY (appointment_id) REFERENCES insaights_appointment(id)
) COMMENT='the appoinments that scheduled the encounter';

CREATE TABLE insaights_encounter_virtual_service (
    id VARCHAR(64) PRIMARY KEY COMMENT 'id for the virtual service record',
    
    encounter_id             VARCHAR(64) NOT NULL COMMENT 'Reference to the parent Encounter (Encounter.id)',
    
    channel_type_code        VARCHAR(32) COMMENT 'Coding.system + Coding.code representing the type of channel (e.g., video, phone, chat)',
    address_url              VARCHAR(255) COMMENT 'addressUri: Direct URI to join the session (e.g., Zoom/Teams meeting link)',
    address_string           VARCHAR(255) COMMENT 'addressString: Free-text description of the location (e.g., "Meeting Room 1")',
    address_contact_point    VARCHAR(255) COMMENT 'addressContactPoint: Contact information such as phone number or email',
    address_extended_detail  TEXT COMMENT 'Extended contact details or structured JSON for advanced addressing',
    
    max_participants         INT COMMENT 'Maximum number of participants allowed in the virtual session',
    session_key              VARCHAR(100) COMMENT 'Session key, access code, or password required for joining',
    additional_info_urls     TEXT COMMENT 'JSON array or comma-separated list of additional information URLs (FHIR.additionalInfo)',
    
    CONSTRAINT fk_encounter_virtual_service_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT='Represents virtual/telehealth connection details associated with an Encounter, aligned with FHIR Encounter.virtualService backbone element';

CREATE TABLE insaights_encounter_reason (
    id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this reason entry (UUID or FHIR id)',
    
    encounter_id 			VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; the encounter this reason belongs to',
    
    CONSTRAINT fk_encounter_reason_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT='Medical reasons associated with an encounter (FHIR: Encounter.reason) to be expressed during that encounter';

CREATE TABLE insaights_encounter_reason_use (
    id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this use entry',
    
    reason_id     			VARCHAR(64) NOT NULL COMMENT 'FK to the reason entry',
    use_code      			VARCHAR(32) COMMENT 'Code indicating how this reason is used (e.g., admission, billing, chief-complaint)',
    
    CONSTRAINT fk_reason_use_reason FOREIGN KEY (reason_id) REFERENCES insaights_encounter_reason(id)
) COMMENT='Indicates how the reason should be used (FHIR: Encounter.reason.use)';

CREATE TABLE insaights_encounter_reason_value (
    id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this value entry',
    
    reason_id            	VARCHAR(64) NOT NULL COMMENT 'FK to the reason entry',
    value_type_code         VARCHAR(32) COMMENT '(Condition, Observation, Procedure, etc.)',
    value_reference_id    	VARCHAR(64) COMMENT 'ID of the referenced resource',
    
    CONSTRAINT fk_reason_value_reason FOREIGN KEY (reason_id) REFERENCES insaights_encounter_reason(id)
) COMMENT='Reason for the encounter expressed as a coded concept or reference to another FHIR resource';

CREATE TABLE insaights_encounter_diagnosis (
    id VARCHAR(64) PRIMARY KEY NOT NULL COMMENT 'Unique identifier for this diagnosis entry (UUID or FHIR id)',
    encounter_id 			VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; the encounter this diagnosis belongs to',
    
    CONSTRAINT fk_encounter_diagnosis_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT='Diagnosis entries associated with an encounter (FHIR: Encounter.diagnosis)';

CREATE TABLE insaights_encounter_diagnosis_condition (
    id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this condition entry',
    
    diagnosis_id 		VARCHAR(64) NOT NULL COMMENT 'FK to the parent diagnosis entry',
    condition_id 		VARCHAR(64) COMMENT 'FK to Condition resource',
    value_code   		VARCHAR(32) COMMENT 'coded concept for the diagnosis',
    
    CONSTRAINT fk_diag_condition_diagnosis FOREIGN KEY (diagnosis_id) REFERENCES insaights_encounter_diagnosis(id),
    CONSTRAINT fk_diag_condition_condition FOREIGN KEY (condition_id) REFERENCES insaights_condition(id)
) COMMENT='Condition(s) linked to a diagnosis entry (FHIR: Encounter.diagnosis.condition)';

CREATE TABLE insaights_encounter_diagnosis_use (
    id	VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for this use entry',
    
    diagnosis_id 		VARCHAR(64) NOT NULL COMMENT 'FK to the encounter diagnosis entry',
    use_code     		VARCHAR(32) COMMENT 'Code indicating the role of this diagnosis within the encounter (e.g., admission, billing, discharge)',

    CONSTRAINT fk_diagnosis_use_diagnosis FOREIGN KEY (diagnosis_id) REFERENCES insaights_encounter_diagnosis(id)
) COMMENT='Role(s) that this diagnosis has within the encounter (FHIR: Encounter.diagnosis.use)';



-- continue

CREATE TABLE insaights_encounter_admission (
    encounter_id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'FK to the encounter; identifies the encounter being admitted',
    pre_admission_identifier 	VARCHAR(64) COMMENT 'Identifier used before formal admission, if any',
    admission_number 			VARCHAR(64) COMMENT 'Hospital-generated admission number',
    
    origin_type 				VARCHAR(32) COMMENT 'Code indicating source of patient before admission (organization or location)',
	origin_id   				VARCHAR(64) COMMENT 'ID of the resource representing where the patient came from (Location or Organization)',
    destination_type 			VARCHAR(32) COMMENT 'Code indicating destination after discharge (organization or location)',
    destination_id 				VARCHAR(64) COMMENT 'FK to location where patient went after discharge',
    
    admit_source_code 			VARCHAR(32) COMMENT 'Code representing reason/source of admission (physician referral, transfer, etc.)',
    re_admission_code 			VARCHAR(32) COMMENT 'Code indicating if this is a re-admission',
    discharge_disposition_code  VARCHAR(32) COMMENT 'Code indicating patient status at discharge (home, transfer, death, etc.)',
    
    admitting_practitioner_id 	VARCHAR(64) COMMENT 'FK to practitioner who admitted the patient',
    assigned_bed_type_code 		VARCHAR(32) COMMENT 'Type of bed allocated (Standard, Electric adjustable, Pediatric, ICU-special)',
    assigned_bed_class_code 	VARCHAR(32) COMMENT 'Bed class indicating level of comfort or service (General, Semi-Private, VIP, ICU)',
    bed_allocation_datetime 	DATETIME COMMENT 'Timestamp when bed was allocated to the patient',
	room_tel_num 				VARCHAR(16) COMMENT 'Telephone number associated with the room, if applicable',
    discharge_unit_code 		VARCHAR(32) COMMENT 'Ward or unit from which patient was discharged',
    disch_practitioner_id 		VARCHAR(64) COMMENT 'FK to practitioner who discharged the patient',
    disp_auth_practitioner_id 	VARCHAR(64) COMMENT 'FK to practitioner who authorized discharge',
    
    CONSTRAINT fk_encounter_admission_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT = 'Details of patient admission during an encounter, including origin, bed allocation, and discharge information';

CREATE TABLE insaights_encounter_location (
    id VARCHAR(64) NOT NULL PRIMARY KEY COMMENT 'Unique identifier for the encounter location record',
    
    encounter_id 				VARCHAR(64) NOT NULL COMMENT 'FK to the encounter during which the patient was at this location',
    location_id 				VARCHAR(64) NOT NULL COMMENT 'FK to the location resource (room, ward, ICU, etc.)',
    
    status_code 				VARCHAR(20) COMMENT 'Current status of the patient at this location (e.g., reserved, completed)',
    form_code 					VARCHAR(32) COMMENT 'Type or form of the location (e.g., room, ward, ICU)',
    
    period_start 				DATETIME COMMENT 'Start date/time when the patient was at this location',
    period_end 					DATETIME COMMENT 'End date/time when the patient left this location',
    
    CONSTRAINT fk_encounter_location_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_location_location FOREIGN KEY (location_id) REFERENCES insaights_location(id)
) COMMENT = 'Tracks the patient’s location(s) during an encounter, including status, type, and time period';

CREATE TABLE insaights_encounter_police_report ( 
    encounter_id       VARCHAR(64) NOT NULL COMMENT 'FK to Encounter; identifies the encounter associated with this police report',
    pol_rep_no         VARCHAR(64) COMMENT 'Police report number assigned for this incident',
    pol_stn_id         VARCHAR(64) COMMENT 'FK/ID of the police station involved in the report',
    pol_id             VARCHAR(64) COMMENT 'FK/ID of the police officer handling the case',
    informed_to        VARCHAR(64) COMMENT 'ID or role of the person informed about this report',
    informed_name      VARCHAR(64) COMMENT 'Name of the person informed about this report',
    informed_date_time DATETIME COMMENT 'Date and time when the report was informed',
    post_mortem_req    BOOLEAN COMMENT 'Indicates whether a post-mortem was requested (1 = Yes, 0 = No)',
    
    PRIMARY KEY (encounter_id),
    CONSTRAINT fk_encounter_police_report FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
) COMMENT='Police report details linked to an encounter; includes officer, station, informed party, and post-mortem request';

