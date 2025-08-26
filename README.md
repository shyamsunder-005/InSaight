# InSaight: Medical FHIR Resource Repository

## Overview
InSaight is a comprehensive repository for managing and modeling healthcare data using HL7 FHIR (Fast Healthcare Interoperability Resources) standards. This project provides structured resources and database schemas for core medical entities such as Patients and Encounters, enabling interoperability and standardized data exchange in healthcare applications.

## Features
- **FHIR-Compliant Resources:** JSON representations of Patient and Encounter resources following HL7 FHIR standards.
- **Database Schemas:** SQL scripts for creating normalized tables to store FHIR resource data.
- **Extensible Design:** Easily adaptable for additional FHIR resources and healthcare workflows.

## Repository Structure

| File/Folder                    | Description                                      |
|--------------------------------|--------------------------------------------------|
| `Patient_resource.json`        | FHIR-compliant Patient resource example           |
| `Encounter_resource.json`      | FHIR-compliant Encounter resource example         |
| `patient.sql`                  | SQL schema for Patient and related tables         |
| `encounter.sql`                | SQL schema for Encounter and related tables       |

## Getting Started
1. **Clone the Repository:**
	```
	git clone https://github.com/shyamsunder-005/InSaight.git
	```
2. **Review Resource Files:**
	- Explore the JSON files for FHIR resource structure.
3. **Set Up Database:**
	- Use the provided SQL scripts to create the necessary tables in your database.
4. **Integrate with Applications:**
	- Leverage these resources and schemas in your healthcare applications for FHIR-compliant data management.

## About FHIR
HL7 FHIR (Fast Healthcare Interoperability Resources) is a standard for exchanging healthcare information electronically. It enables interoperability between healthcare systems by defining data formats and elements (known as "resources") and an API for exchanging these resources.

