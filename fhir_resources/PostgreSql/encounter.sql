-- =========================
-- Includes reference tables, Encounter main, Identifier, Type, ServiceType, EpisodeOfCare
-- All comments from MySQL preserved via COMMENT ON statements
-- =========================

-- Reference-only tables (needed for FKs)
CREATE TABLE insaights_group (
    id VARCHAR(64) PRIMARY KEY
);
COMMENT ON TABLE insaights_group IS 'for reference only not permanent';

CREATE TABLE insaights_condition (
    id VARCHAR(64) PRIMARY KEY
);
COMMENT ON TABLE insaights_condition IS 'for reference only not permanent';

CREATE TABLE insaights_episode_of_care (
    id VARCHAR(64) PRIMARY KEY
);
COMMENT ON TABLE insaights_episode_of_care IS 'for reference only not permanent';

CREATE TABLE insaights_care_team (
    id VARCHAR(64) PRIMARY KEY
);
COMMENT ON TABLE insaights_care_team IS 'for reference only not permanent';

CREATE TABLE insaights_appointment (
    id VARCHAR(64) PRIMARY KEY
);
COMMENT ON TABLE insaights_appointment IS 'for reference only not permanent';

CREATE TABLE insaights_account (
    id VARCHAR(64) PRIMARY KEY
);
COMMENT ON TABLE insaights_account IS 'for reference only not permanent';

CREATE TABLE insaights_location (
    id VARCHAR(64) PRIMARY KEY
);
COMMENT ON TABLE insaights_location IS 'for reference only not permanent';

CREATE TABLE insaights_healthcare_service (
    id VARCHAR(64) PRIMARY KEY
);
COMMENT ON TABLE insaights_healthcare_service IS 'for reference only not permanent';

-- -----------------------------------------------------------------------------
-- Encounter main table
CREATE TABLE insaights_encounter (
    id VARCHAR(64) PRIMARY KEY NOT NULL,
    status_code VARCHAR(20) NOT NULL,
    status_set_on_date TIMESTAMP,
    status_set_by_user_id VARCHAR(64),
    status_reason VARCHAR(255),
    adt_status VARCHAR(32),
    priority_code VARCHAR(32),
    subject_patient_id VARCHAR(64),
    subject_group_id VARCHAR(64),
    subject_status_code VARCHAR(32),
    part_of_encounter_id VARCHAR(64),
    service_provider_org_id VARCHAR(64),
    planned_start TIMESTAMP,
    planned_end TIMESTAMP,
    actual_start TIMESTAMP,
    actual_end TIMESTAMP,
    length_quantity DECIMAL(6,2),
    length_unit VARCHAR(10),
    class_code VARCHAR(32),
    recall_yn BOOLEAN,
    recall_date DATE,
    patient_type_code VARCHAR(32),
    fiscal_year VARCHAR(16),
    fiscal_period VARCHAR(16),
    shift_id VARCHAR(32),
    backdated_yn BOOLEAN NOT NULL,
    brought_dead BOOLEAN NOT NULL,
    priority_zone_code VARCHAR(32),
    security_level_code VARCHAR(32) DEFAULT 'NORMAL',
    protection_ind BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(64) NOT NULL,
    modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by VARCHAR(64) NOT NULL DEFAULT 'SYSTEM',
    CONSTRAINT chk_recall CHECK ((recall_yn = TRUE AND recall_date IS NOT NULL) OR (recall_yn = FALSE AND recall_date IS NULL)),
    CONSTRAINT chk_pat_grp CHECK ((subject_patient_id IS NOT NULL AND subject_group_id IS NULL) OR (subject_patient_id IS NULL AND subject_group_id IS NOT NULL)),
    CONSTRAINT fk_encounter_subject_patient FOREIGN KEY (subject_patient_id) REFERENCES insaights_patient(id),
    CONSTRAINT fk_encounter_subject_group FOREIGN KEY (subject_group_id) REFERENCES insaights_group(id),
    CONSTRAINT fk_encounter_part_of FOREIGN KEY (part_of_encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_service_provider FOREIGN KEY (service_provider_org_id) REFERENCES insaights_organisation(id)
);
COMMENT ON TABLE insaights_encounter IS 'An interaction between a patient and the healthcare system';
COMMENT ON COLUMN insaights_encounter.id IS 'Unique indentifier - hospital generated or..';
COMMENT ON COLUMN insaights_encounter.status_code IS 'Status of the visit: planned, in-progress, on-hold, etc.';
COMMENT ON COLUMN insaights_encounter.status_set_on_date IS 'Date/time when this status was assigned';
COMMENT ON COLUMN insaights_encounter.status_set_by_user_id IS 'FK to staff who assigned the status';
COMMENT ON COLUMN insaights_encounter.status_reason IS 'Reason why the status was updated (e.g., patient left early, admitted late)';
COMMENT ON COLUMN insaights_encounter.adt_status IS 'Custom administrative status (e.g., check-in, pre-admit, discharged)';
COMMENT ON COLUMN insaights_encounter.priority_code IS 'Encounter priority (e.g., A-ASAP, R-Routine)';
COMMENT ON COLUMN insaights_encounter.subject_patient_id IS 'FK to the patient involved in this encounter';
COMMENT ON COLUMN insaights_encounter.subject_group_id IS 'FK to the patient group involved, if applicable';
COMMENT ON COLUMN insaights_encounter.subject_status_code IS 'Patient status during encounter (arrived, triaged, on-leave)';
COMMENT ON COLUMN insaights_encounter.part_of_encounter_id IS 'FK to a parent encounter, if this is a sub-encounter';
COMMENT ON COLUMN insaights_encounter.service_provider_org_id IS 'FK to the organization providing the service';
COMMENT ON COLUMN insaights_encounter.planned_start IS 'Scheduled start of the encounter';
COMMENT ON COLUMN insaights_encounter.planned_end IS 'Scheduled end of the encounter';
COMMENT ON COLUMN insaights_encounter.actual_start IS 'Actual start date/time of the encounter';
COMMENT ON COLUMN insaights_encounter.actual_end IS 'Actual end date/time of the encounter';
COMMENT ON COLUMN insaights_encounter.length_quantity IS 'Duration of the encounter';
COMMENT ON COLUMN insaights_encounter.length_unit IS 'Unit of duration (min, hr, etc.)';
COMMENT ON COLUMN insaights_encounter.class_code IS 'Type/classification of encounter (inpatient, outpatient, virtual, home health)';
COMMENT ON COLUMN insaights_encounter.recall_yn IS 'Indicates if a follow-up is required';
COMMENT ON COLUMN insaights_encounter.recall_date IS 'Follow-up date if recall_yn is true';
COMMENT ON COLUMN insaights_encounter.patient_type_code IS 'whether the patient is new or returning or general patient';
COMMENT ON COLUMN insaights_encounter.fiscal_year IS 'Fiscal or reporting year for the encounter (e.g., 2024-2025)';
COMMENT ON COLUMN insaights_encounter.fiscal_period IS 'Reporting month, quarter, or period for the encounter (e.g., Jan, Q1, FY24Q1)';
COMMENT ON COLUMN insaights_encounter.shift_id IS 'Shift during which the encounter occurred';
COMMENT ON COLUMN insaights_encounter.backdated_yn IS 'Indicates whether the encounter is backdated: TRUE or FALSE';
COMMENT ON COLUMN insaights_encounter.brought_dead IS 'Patient brought dead flag (1 = Yes, 0 = No)';
COMMENT ON COLUMN insaights_encounter.priority_zone_code IS 'Emergency triage or priority zone code assigned to the patient during this encounter, red,green, blue';
COMMENT ON COLUMN insaights_encounter.security_level_code IS 'Access restriction level (NORMAL, RESTRICTED, CONFIDENTIAL, HIGHLY_CONFIDENTIAL)';
COMMENT ON COLUMN insaights_encounter.protection_ind IS 'Boolean protection indicator; TRUE = additional protection required';

-- -----------------------------------------------------------------------------
-- Encounter Identifier
CREATE TABLE insaights_encounter_identifier (
    id VARCHAR(64) PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id VARCHAR(64) NOT NULL,
    use_code VARCHAR(32),
    type_code VARCHAR(32),
    system VARCHAR(255),
    value VARCHAR(255),
    period_start TIMESTAMP,
    period_end TIMESTAMP,
    assigner_id VARCHAR(64),
    CONSTRAINT fk_encounter_identifier_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_identifier_assigner FOREIGN KEY (assigner_id) REFERENCES insaights_organisation(id)
);
COMMENT ON TABLE insaights_encounter_identifier IS 'Stores one or more identifiers for each encounter';
COMMENT ON COLUMN insaights_encounter_identifier.id IS 'Unique identifier for the encounter identifier record';
COMMENT ON COLUMN insaights_encounter_identifier.encounter_id IS 'FK to the encounter this identifier belongs to';
COMMENT ON COLUMN insaights_encounter_identifier.use_code IS 'Purpose of this identifier (usual, official, temp, secondary, old)';
COMMENT ON COLUMN insaights_encounter_identifier.type_code IS 'Code indicating the type of identifier';
COMMENT ON COLUMN insaights_encounter_identifier.system IS 'The identifier system or namespace (e.g., hospital MRN, external registry)';
COMMENT ON COLUMN insaights_encounter_identifier.value IS 'The identifier value assigned to the encounter';
COMMENT ON COLUMN insaights_encounter_identifier.period_start IS 'Start date/time for which this identifier is valid';
COMMENT ON COLUMN insaights_encounter_identifier.period_end IS 'End date/time for which this identifier is valid';
COMMENT ON COLUMN insaights_encounter_identifier.assigner_id IS 'FK to the organization that assigned this identifier';

-- -----------------------------------------------------------------------------
-- Encounter Type
CREATE TABLE insaights_encounter_type (
    id VARCHAR(64) PRIMARY KEY DEFAULT gen_random_uuid(),
    encounter_id VARCHAR(64) NOT NULL,
    type_code VARCHAR(32),
    CONSTRAINT fk_encounter_type_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_type IS 'Stores the specific types or categories of an encounter, allowing multiple types per encounter (e.g., cardiology consultation and diagnostic imaging in the same visit)';
COMMENT ON COLUMN insaights_encounter_type.id IS 'Unique identifier for the encounter type record';
COMMENT ON COLUMN insaights_encounter_type.encounter_id IS 'FK to the encounter during which this type is recorded';
COMMENT ON COLUMN insaights_encounter_type.type_code IS 'Standardized code representing the encounter type (FHIR Encounter.type), e.g., ADMS, EMER, BD/BM-clin';

-- -----------------------------------------------------------------------------
-- Encounter Service Type
CREATE TABLE insaights_encounter_service_type (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    service_id VARCHAR(64),
    service_code VARCHAR(32),
    CONSTRAINT fk_encounter_service_type_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_service_type IS 'Tracks the specific healthcare services delivered during an encounter, linking each encounter to one or more service types';
COMMENT ON COLUMN insaights_encounter_service_type.id IS 'Unique identifier for the encounter-service type record';
COMMENT ON COLUMN insaights_encounter_service_type.encounter_id IS 'FK to the encounter during which this service was provided';
COMMENT ON COLUMN insaights_encounter_service_type.service_id IS 'FK to the HealthcareService resource representing the specific service provided (e.g., Cardiology, Radiology, Pediatrics)';
COMMENT ON COLUMN insaights_encounter_service_type.service_code IS 'Optional standardized code representing the type of service provided like card';

-- -----------------------------------------------------------------------------
-- Encounter Episode Of Care
CREATE TABLE insaights_encounter_episode_of_care (
    encounter_id VARCHAR(64) NOT NULL,
    visit_number INT,
    episode_of_care_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (encounter_id, episode_of_care_id),
    CONSTRAINT fk_encounter_episode_encounter FOREIGN KEY (encounter_id) REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_episode_episode FOREIGN KEY (episode_of_care_id) REFERENCES insaights_episode_of_care(id)
);
COMMENT ON TABLE insaights_encounter_episode_of_care IS 'Associates individual encounters with their corresponding episode of care, representing a longer care journey or treatment plan for the patient';
COMMENT ON COLUMN insaights_encounter_episode_of_care.encounter_id IS 'FK to the encounter that is part of an episode of care';
COMMENT ON COLUMN insaights_encounter_episode_of_care.visit_number IS 'Sequential visit number for the patient under the episode of care';
COMMENT ON COLUMN insaights_encounter_episode_of_care.episode_of_care_id IS 'FK to the episode of care grouping this encounter with others for a specific condition or treatment plan';

-- -----------------------------------------------------------------------------
-- Encounter BasedOn
CREATE TABLE insaights_encounter_based_on (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    target_type VARCHAR(64) NOT NULL,
    target_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_encounter_based_on_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_based_on IS 'Links an Encounter to the requests (ServiceRequest, Appointment, Referral, etc.) that caused it to occur';
COMMENT ON COLUMN insaights_encounter_based_on.id IS 'Unique identifier for this record; allows multiple requests to be linked to one encounter';
COMMENT ON COLUMN insaights_encounter_based_on.encounter_id IS 'FK to insaights_encounter; identifies the encounter this record belongs to';
COMMENT ON COLUMN insaights_encounter_based_on.target_type IS 'FHIR resource type of the request that triggered the encounter (e.g., Appointment, ServiceRequest, ReferralRequest)';
COMMENT ON COLUMN insaights_encounter_based_on.target_id IS 'ID of the specific resource instance (Appointment ID, ServiceRequest ID, etc.)';

-- -----------------------------------------------------------------------------
-- Encounter CareTeam
CREATE TABLE insaights_encounter_care_team (
    encounter_id VARCHAR(64) NOT NULL,
    care_team_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (encounter_id, care_team_id),
    CONSTRAINT fk_encounter_care_team_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_care_team IS 'Associative table linking encounters with care teams, representing healthcare providers/groups involved in the encounter';
COMMENT ON COLUMN insaights_encounter_care_team.encounter_id IS 'FK to insaights_encounter; identifies the encounter';
COMMENT ON COLUMN insaights_encounter_care_team.care_team_id IS 'FK to insaights_care_team; identifies the care team involved';

-- -----------------------------------------------------------------------------
-- Encounter Participant
CREATE TABLE insaights_encounter_participant (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    period_start TIMESTAMP,
    period_end TIMESTAMP,
    actor_type_code VARCHAR(32),
    actor_ref_id VARCHAR(64),
    CONSTRAINT fk_encounter_participant_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_participant IS 'FHIR Encounter.participant: Participants involved in an encounter, their roles, actor type, and period of involvement';
COMMENT ON COLUMN insaights_encounter_participant.id IS 'Unique identifier for this participant entry (UUID or FHIR id)';
COMMENT ON COLUMN insaights_encounter_participant.encounter_id IS 'FK to Encounter; the encounter this participant is associated with';
COMMENT ON COLUMN insaights_encounter_participant.period_start IS 'Start time of the participant’s involvement during the encounter';
COMMENT ON COLUMN insaights_encounter_participant.period_end IS 'End time of the participant’s involvement during the encounter';
COMMENT ON COLUMN insaights_encounter_participant.actor_type_code IS 'Type of the actor (Patient, Practitioner, related person, etc.)';
COMMENT ON COLUMN insaights_encounter_participant.actor_ref_id IS 'Reference to the participant actor (FK to Patient, Practitioner, or other relevant resource) or handle in application lv';

-- -----------------------------------------------------------------------------
-- Participant Type
CREATE TABLE insaights_encounter_participant_type (
    id VARCHAR(64) PRIMARY KEY,
    participant_id VARCHAR(64) NOT NULL,
    type_code VARCHAR(32),
    CONSTRAINT fk_participant_type_participant FOREIGN KEY (participant_id)
        REFERENCES insaights_encounter_participant(id)
);
COMMENT ON TABLE insaights_encounter_participant_type IS 'FHIR Encounter.participant.type: Roles or functions the participant has in the encounter';
COMMENT ON COLUMN insaights_encounter_participant_type.id IS 'Unique identifier for this participant role entry';
COMMENT ON COLUMN insaights_encounter_participant_type.participant_id IS 'FK to participant';
COMMENT ON COLUMN insaights_encounter_participant_type.type_code IS 'Role of the participant in the encounter (e.g., attender, consultant, observer)';

-- -----------------------------------------------------------------------------
-- Encounter Account
CREATE TABLE insaights_encounter_account (
    encounter_id VARCHAR(64) NOT NULL,
    account_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (encounter_id, account_id),
    CONSTRAINT fk_encounter_account_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_account_account FOREIGN KEY (account_id)
        REFERENCES insaights_account(id)
);
COMMENT ON TABLE insaights_encounter_account IS 'Billing accounts linked to an encounter. Supports multiple accounts per encounter (e.g., hospital charges, lab charges) in line with FHIR Encounter.account';
COMMENT ON COLUMN insaights_encounter_account.encounter_id IS 'FK to Encounter; the encounter associated with this billing account';
COMMENT ON COLUMN insaights_encounter_account.account_id IS 'FK to Account; the billing account linked to this encounter';

-- -----------------------------------------------------------------------------
-- Encounter Diet Preference
CREATE TABLE insaights_encounter_diet_preference (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    diet_code VARCHAR(32),
    CONSTRAINT fk_encounter_diet_preference_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_diet_preference IS 'Patient-reported diet preferences during an encounter (FHIR: Encounter.extension[dietPreference])';
COMMENT ON COLUMN insaights_encounter_diet_preference.id IS 'Unique identifier for the diet preference entry (UUID or FHIR id)';
COMMENT ON COLUMN insaights_encounter_diet_preference.encounter_id IS 'FK to Encounter; the encounter during which this diet preference was reported';
COMMENT ON COLUMN insaights_encounter_diet_preference.diet_code IS 'Code representing the patient’s diet preference (e.g., vegetarian, vegan, gluten-free)';

-- -----------------------------------------------------------------------------
-- Encounter Special Arrangement
CREATE TABLE insaights_encounter_special_arrangement (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    arrangement_code VARCHAR(32),
    CONSTRAINT fk_encounter_special_arrangement_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_special_arrangement IS 'Special arrangements needed during an encounter (FHIR: Encounter.extension[specialArrangement])';
COMMENT ON COLUMN insaights_encounter_special_arrangement.id IS 'Unique identifier for this special arrangement entry';
COMMENT ON COLUMN insaights_encounter_special_arrangement.encounter_id IS 'FK to Encounter; the encounter requiring this special arrangement';
COMMENT ON COLUMN insaights_encounter_special_arrangement.arrangement_code IS 'Code for special arrangements requested or provided (e.g., wheelchair, translator, stretcher)';

-- -----------------------------------------------------------------------------
-- Encounter Special Courtesy
CREATE TABLE insaights_encounter_special_courtesy (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    courtesy_code VARCHAR(50),
    CONSTRAINT fk_encounter_special_courtesy_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_special_courtesy IS 'Special courtesies granted during an encounter (FHIR: Encounter.extension[specialCourtesy])';
COMMENT ON COLUMN insaights_encounter_special_courtesy.id IS 'Unique identifier for this courtesy entry';
COMMENT ON COLUMN insaights_encounter_special_courtesy.encounter_id IS 'FK to Encounter; the encounter where the courtesy applies';
COMMENT ON COLUMN insaights_encounter_special_courtesy.courtesy_code IS 'Code indicating special courtesy or privilege (e.g., VIP, board member)';

-- -----------------------------------------------------------------------------
-- Encounter Appointment
CREATE TABLE insaights_encounter_appointment (
    encounter_id VARCHAR(64) NOT NULL,
    appointment_id VARCHAR(64) NOT NULL,
    PRIMARY KEY (encounter_id, appointment_id),
    CONSTRAINT fk_encounter_appointment_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_appointment_appointment FOREIGN KEY (appointment_id)
        REFERENCES insaights_appointment(id)
);
COMMENT ON TABLE insaights_encounter_appointment IS 'the appointments that scheduled the encounter';
COMMENT ON COLUMN insaights_encounter_appointment.encounter_id IS 'FK to Encounter; the encounter that was scheduled by this appointment';
COMMENT ON COLUMN insaights_encounter_appointment.appointment_id IS 'FK to Appointment; the appointment that scheduled this encounter';

-- -----------------------------------------------------------------------------
-- Encounter Virtual Service
CREATE TABLE insaights_encounter_virtual_service (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    channel_type_code VARCHAR(32),
    address_url VARCHAR(255),
    address_string VARCHAR(255),
    address_contact_point VARCHAR(255),
    address_extended_detail TEXT,
    max_participants INT,
    session_key VARCHAR(100),
    additional_info_urls TEXT,
    CONSTRAINT fk_encounter_virtual_service_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_virtual_service IS 'Represents virtual/telehealth connection details associated with an Encounter, aligned with FHIR Encounter.virtualService backbone element';
COMMENT ON COLUMN insaights_encounter_virtual_service.id IS 'id for the virtual service record';
COMMENT ON COLUMN insaights_encounter_virtual_service.encounter_id IS 'Reference to the parent Encounter (Encounter.id)';
COMMENT ON COLUMN insaights_encounter_virtual_service.channel_type_code IS 'Coding.system + Coding.code representing the type of channel (e.g., video, phone, chat)';
COMMENT ON COLUMN insaights_encounter_virtual_service.address_url IS 'addressUri: Direct URI to join the session (e.g., Zoom/Teams meeting link)';
COMMENT ON COLUMN insaights_encounter_virtual_service.address_string IS 'addressString: Free-text description of the location (e.g., "Meeting Room 1")';
COMMENT ON COLUMN insaights_encounter_virtual_service.address_contact_point IS 'addressContactPoint: Contact information such as phone number or email';
COMMENT ON COLUMN insaights_encounter_virtual_service.address_extended_detail IS 'Extended contact details or structured JSON for advanced addressing';
COMMENT ON COLUMN insaights_encounter_virtual_service.max_participants IS 'Maximum number of participants allowed in the virtual session';
COMMENT ON COLUMN insaights_encounter_virtual_service.session_key IS 'Session key, access code, or password required for joining';
COMMENT ON COLUMN insaights_encounter_virtual_service.additional_info_urls IS 'JSON array or comma-separated list of additional information URLs (FHIR.additionalInfo)';

-- -----------------------------------------------------------------------------
-- Encounter Reason
CREATE TABLE insaights_encounter_reason (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_encounter_reason_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_reason IS 'Medical reasons associated with an encounter (FHIR: Encounter.reason) to be expressed during that encounter';
COMMENT ON COLUMN insaights_encounter_reason.id IS 'Unique identifier for this reason entry (UUID or FHIR id)';
COMMENT ON COLUMN insaights_encounter_reason.encounter_id IS 'FK to Encounter; the encounter this reason belongs to';

-- -----------------------------------------------------------------------------
-- Encounter Reason Use
CREATE TABLE insaights_encounter_reason_use (
    id VARCHAR(64) PRIMARY KEY,
    reason_id VARCHAR(64) NOT NULL,
    use_code VARCHAR(32),
    CONSTRAINT fk_reason_use_reason FOREIGN KEY (reason_id)
        REFERENCES insaights_encounter_reason(id)
);
COMMENT ON TABLE insaights_encounter_reason_use IS 'Indicates how the reason should be used (FHIR: Encounter.reason.use)';
COMMENT ON COLUMN insaights_encounter_reason_use.id IS 'Unique identifier for this use entry';
COMMENT ON COLUMN insaights_encounter_reason_use.reason_id IS 'FK to the reason entry';
COMMENT ON COLUMN insaights_encounter_reason_use.use_code IS 'Code indicating how this reason is used (e.g., admission, billing, chief-complaint)';

-- -----------------------------------------------------------------------------
-- Encounter Reason Value
CREATE TABLE insaights_encounter_reason_value (
    id VARCHAR(64) PRIMARY KEY,
    reason_id VARCHAR(64) NOT NULL,
    value_type_code VARCHAR(32),
    value_reference_id VARCHAR(64),
    CONSTRAINT fk_reason_value_reason FOREIGN KEY (reason_id)
        REFERENCES insaights_encounter_reason(id)
);
COMMENT ON TABLE insaights_encounter_reason_value IS 'Reason for the encounter expressed as a coded concept or reference to another FHIR resource';
COMMENT ON COLUMN insaights_encounter_reason_value.id IS 'Unique identifier for this value entry';
COMMENT ON COLUMN insaights_encounter_reason_value.reason_id IS 'FK to the reason entry';
COMMENT ON COLUMN insaights_encounter_reason_value.value_type_code IS '(Condition, Observation, Procedure, etc.)';
COMMENT ON COLUMN insaights_encounter_reason_value.value_reference_id IS 'ID of the referenced resource';

-- -----------------------------------------------------------------------------
-- Encounter Diagnosis
CREATE TABLE insaights_encounter_diagnosis (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    CONSTRAINT fk_encounter_diagnosis_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_diagnosis IS 'Diagnosis entries associated with an encounter (FHIR: Encounter.diagnosis)';
COMMENT ON COLUMN insaights_encounter_diagnosis.id IS 'Unique identifier for this diagnosis entry (UUID or FHIR id)';
COMMENT ON COLUMN insaights_encounter_diagnosis.encounter_id IS 'FK to Encounter; the encounter this diagnosis belongs to';

-- -----------------------------------------------------------------------------
-- Encounter Diagnosis Condition
CREATE TABLE insaights_encounter_diagnosis_condition (
    id VARCHAR(64) PRIMARY KEY,
    diagnosis_id VARCHAR(64) NOT NULL,
    condition_id VARCHAR(64),
    value_code VARCHAR(32),
    CONSTRAINT fk_diag_condition_diagnosis FOREIGN KEY (diagnosis_id)
        REFERENCES insaights_encounter_diagnosis(id),
    CONSTRAINT fk_diag_condition_condition FOREIGN KEY (condition_id)
        REFERENCES insaights_condition(id)
);
COMMENT ON TABLE insaights_encounter_diagnosis_condition IS 'Condition(s) linked to a diagnosis entry (FHIR: Encounter.diagnosis.condition)';
COMMENT ON COLUMN insaights_encounter_diagnosis_condition.id IS 'Unique identifier for this condition entry';
COMMENT ON COLUMN insaights_encounter_diagnosis_condition.diagnosis_id IS 'FK to the parent diagnosis entry';
COMMENT ON COLUMN insaights_encounter_diagnosis_condition.condition_id IS 'FK to Condition resource';
COMMENT ON COLUMN insaights_encounter_diagnosis_condition.value_code IS 'coded concept for the diagnosis';

-- -----------------------------------------------------------------------------
-- Encounter Diagnosis Use
CREATE TABLE insaights_encounter_diagnosis_use (
    id VARCHAR(64) PRIMARY KEY,
    diagnosis_id VARCHAR(64) NOT NULL,
    use_code VARCHAR(32),
    CONSTRAINT fk_diagnosis_use_diagnosis FOREIGN KEY (diagnosis_id)
        REFERENCES insaights_encounter_diagnosis(id)
);
COMMENT ON TABLE insaights_encounter_diagnosis_use IS 'Role(s) that this diagnosis has within the encounter (FHIR: Encounter.diagnosis.use)';
COMMENT ON COLUMN insaights_encounter_diagnosis_use.id IS 'Unique identifier for this use entry';
COMMENT ON COLUMN insaights_encounter_diagnosis_use.diagnosis_id IS 'FK to the encounter diagnosis entry';
COMMENT ON COLUMN insaights_encounter_diagnosis_use.use_code IS 'Code indicating the role of this diagnosis within the encounter (e.g., admission, billing, discharge)';

-- -----------------------------------------------------------------------------
-- Encounter Admission
CREATE TABLE insaights_encounter_admission (
    encounter_id VARCHAR(64) PRIMARY KEY,
    pre_admission_identifier VARCHAR(64),
    admission_number VARCHAR(64),
    origin_type VARCHAR(32),
    origin_id VARCHAR(64),
    destination_type VARCHAR(32),
    destination_id VARCHAR(64),
    admit_source_code VARCHAR(32),
    re_admission_code VARCHAR(32),
    discharge_disposition_code VARCHAR(32),
    admitting_practitioner_id VARCHAR(64),
    assigned_bed_type_code VARCHAR(32),
    assigned_bed_class_code VARCHAR(32),
    bed_allocation_datetime TIMESTAMP,
    room_tel_num VARCHAR(16),
    discharge_unit_code VARCHAR(32),
    disch_practitioner_id VARCHAR(64),
    disp_auth_practitioner_id VARCHAR(64),
    CONSTRAINT fk_encounter_admission_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_admission IS 'Details of patient admission during an encounter, including origin, bed allocation, and discharge information';
COMMENT ON COLUMN insaights_encounter_admission.encounter_id IS 'FK to the encounter; identifies the encounter being admitted';
COMMENT ON COLUMN insaights_encounter_admission.pre_admission_identifier IS 'Identifier used before formal admission, if any';
COMMENT ON COLUMN insaights_encounter_admission.admission_number IS 'Hospital-generated admission number';
COMMENT ON COLUMN insaights_encounter_admission.origin_type IS 'Code indicating source of patient before admission (organization or location)';
COMMENT ON COLUMN insaights_encounter_admission.origin_id IS 'ID of the resource representing where the patient came from (Location or Organization)';
COMMENT ON COLUMN insaights_encounter_admission.destination_type IS 'Code indicating destination after discharge (organization or location)';
COMMENT ON COLUMN insaights_encounter_admission.destination_id IS 'FK to location where patient went after discharge';
COMMENT ON COLUMN insaights_encounter_admission.admit_source_code IS 'Code representing reason/source of admission (physician referral, transfer, etc.)';
COMMENT ON COLUMN insaights_encounter_admission.re_admission_code IS 'Code indicating if this is a re-admission';
COMMENT ON COLUMN insaights_encounter_admission.discharge_disposition_code IS 'Code indicating patient status at discharge (home, transfer, death, etc.)';
COMMENT ON COLUMN insaights_encounter_admission.admitting_practitioner_id IS 'FK to practitioner who admitted the patient';
COMMENT ON COLUMN insaights_encounter_admission.assigned_bed_type_code IS 'Type of bed allocated (Standard, Electric adjustable, Pediatric, ICU-special)';
COMMENT ON COLUMN insaights_encounter_admission.assigned_bed_class_code IS 'Bed class indicating level of comfort or service (General, Semi-Private, VIP, ICU)';
COMMENT ON COLUMN insaights_encounter_admission.bed_allocation_datetime IS 'Timestamp when bed was allocated to the patient';
COMMENT ON COLUMN insaights_encounter_admission.room_tel_num IS 'Telephone number associated with the room, if applicable';
COMMENT ON COLUMN insaights_encounter_admission.discharge_unit_code IS 'Ward or unit from which patient was discharged';
COMMENT ON COLUMN insaights_encounter_admission.disch_practitioner_id IS 'FK to practitioner who discharged the patient';
COMMENT ON COLUMN insaights_encounter_admission.disp_auth_practitioner_id IS 'FK to practitioner who authorized discharge';

-- -----------------------------------------------------------------------------
-- Encounter Location
CREATE TABLE insaights_encounter_location (
    id VARCHAR(64) PRIMARY KEY,
    encounter_id VARCHAR(64) NOT NULL,
    location_id VARCHAR(64) NOT NULL,
    status_code VARCHAR(20),
    form_code VARCHAR(32),
    period_start TIMESTAMP,
    period_end TIMESTAMP,
    CONSTRAINT fk_encounter_location_encounter FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id),
    CONSTRAINT fk_encounter_location_location FOREIGN KEY (location_id)
        REFERENCES insaights_location(id)
);
COMMENT ON TABLE insaights_encounter_location IS 'Tracks the patient’s location(s) during an encounter, including status, type, and time period';
COMMENT ON COLUMN insaights_encounter_location.id IS 'Unique identifier for the encounter location record';
COMMENT ON COLUMN insaights_encounter_location.encounter_id IS 'FK to the encounter during which the patient was at this location';
COMMENT ON COLUMN insaights_encounter_location.location_id IS 'FK to the location resource (room, ward, ICU, etc.)';
COMMENT ON COLUMN insaights_encounter_location.status_code IS 'Current status of the patient at this location (e.g., reserved, completed)';
COMMENT ON COLUMN insaights_encounter_location.form_code IS 'Type or form of the location (e.g., room, ward, ICU)';
COMMENT ON COLUMN insaights_encounter_location.period_start IS 'Start date/time when the patient was at this location';
COMMENT ON COLUMN insaights_encounter_location.period_end IS 'End date/time when the patient left this location';

-- -----------------------------------------------------------------------------
-- Encounter Police Report
CREATE TABLE insaights_encounter_police_report (
    encounter_id VARCHAR(64) PRIMARY KEY,
    pol_rep_no VARCHAR(64),
    pol_stn_id VARCHAR(64),
    pol_id VARCHAR(64),
    informed_to VARCHAR(64),
    informed_name VARCHAR(64),
    informed_date_time TIMESTAMP,
    post_mortem_req BOOLEAN,
    CONSTRAINT fk_encounter_police_report FOREIGN KEY (encounter_id)
        REFERENCES insaights_encounter(id)
);
COMMENT ON TABLE insaights_encounter_police_report IS 'Police report details linked to an encounter; includes officer, station, informed party, and post-mortem request';
COMMENT ON COLUMN insaights_encounter_police_report.encounter_id IS 'FK to Encounter; identifies the encounter associated with this police report';
COMMENT ON COLUMN insaights_encounter_police_report.pol_rep_no IS 'Police report number assigned for this incident';
COMMENT ON COLUMN insaights_encounter_police_report.pol_stn_id IS 'FK/ID of the police station involved in the report';
COMMENT ON COLUMN insaights_encounter_police_report.pol_id IS 'FK/ID of the police officer handling the case';
COMMENT ON COLUMN insaights_encounter_police_report.informed_to IS 'ID or role of the person informed about this report';
COMMENT ON COLUMN insaights_encounter_police_report.informed_name IS 'Name of the person informed about this report';
COMMENT ON COLUMN insaights_encounter_police_report.informed_date_time IS 'Date and time when the report was informed';
COMMENT ON COLUMN insaights_encounter_police_report.post_mortem_req IS 'Indicates whether a post-mortem was requested (1 = Yes, 0 = No)';
