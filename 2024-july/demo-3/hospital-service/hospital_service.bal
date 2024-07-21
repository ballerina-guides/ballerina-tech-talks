import ballerina/http;
import ballerina/uuid;

listener http:Listener hospitalEP = new (9090);

service /hospital on hospitalEP {
    # Get a list of patients
    #
    # + return - A list of patients 
    isolated resource function get patients() returns Patient[] {
        lock {
            return patientTable.toArray().clone();
        }
    }

    # Get a patient by ID
    #
    # + return - returns can be any of following types 
    # http:Ok (Patient details)
    # http:NotFound (Patient not found)
    isolated resource function get patients/[string patientId]() returns Patient|http:NotFound {
        lock {
            if !patientTable.hasKey(patientId) {
                return {body: "Patient not found"};
            }
            return patientTable.get(patientId).clone();
        }
    }

    # Create a new patient
    #
    # + patientEntry - PatientEntry object to be created 
    # + return - Patient created successfully 
    isolated resource function post patients(@http:Payload PatientEntry patientEntry) returns Patient {
        Patient patient = {id: uuid:createRandomUuid(), ...patientEntry};
        lock {
            patientTable.put(patient.clone());
        }
        return patient;
    }

    # Update a patient by ID
    #
    # + patientEntry - Patient object to be updated 
    # + return - returns can be any of following types 
    # http:Ok (Patient updated successfully)
    # http:NotFound (Patient not found)
    isolated resource function put patients/[string patientId](@http:Payload PatientEntry patientEntry) returns Patient|http:NotFound {
        lock {
            if !patientTable.hasKey(patientId) {
                return {body: "Patient not found"};
            }
        }
        Patient patient = {id: patientId, ...patientEntry};
        lock {
            patientTable.put(patient.clone());
        }
        return patient;
    }

    # Delete a patient by ID
    #
    # + return - returns can be any of following types 
    # http:NoContent (Patient deleted successfully)
    # http:NotFound (Patient not found)
    isolated resource function delete patients/[string patientId]() returns Patient|http:NotFound {
        lock {
            if !patientTable.hasKey(patientId) {
                return {body: "Patient not found"};
            }
            return patientTable.remove(patientId).clone();
        }
    }

    # Get a list of medical records
    #
    # + return - A list of medical records 
    isolated resource function get records() returns MedicalRecord[] {
        lock {
            return recordTable.toArray().clone();
        }
    }

    # Get a medical record by ID
    #
    # + return - returns can be any of following types 
    # http:Ok (MedicalRecord details)
    # http:NotFound (MedicalRecord not found)
    isolated resource function get records/[string recordId]() returns MedicalRecord|http:NotFound {
        lock {
            if !recordTable.hasKey(recordId) {
                return {body: "Record not found"};
            }
            return recordTable.get(recordId).clone();
        }
    }

    # Create a new medical record
    #
    # + recordEntry - MedicalRecord object to be created 
    # + return - Medical created successfully 
    isolated resource function post records(@http:Payload MedicalRecordEntry recordEntry) returns MedicalRecord|http:NotFound {
        lock {
            if !patientTable.hasKey(recordEntry.patientId) {
                return {body: "Patient not found"};
            }
        }
        MedicalRecord medRecord = {id: uuid:createRandomUuid(), ...recordEntry};
        lock {
            recordTable.put(medRecord.clone());
        }
        return medRecord;
    }

    # Update a recoed by ID
    #
    # + recordEntry - Medical record object to be updated 
    # + return - returns can be any of following types 
    # http:Ok (Medical record updated successfully)
    # http:NotFound (Medical record or Patient not found)
    isolated resource function put records/[string recordId](@http:Payload MedicalRecordEntry recordEntry) returns MedicalRecord|http:NotFound {
        lock {
            if !patientTable.hasKey(recordEntry.patientId) {
                return {body: "Patient not found"};
            }
        }
        lock {
            if !recordTable.hasKey(recordId) {
                return {body: "Medical record not found"};
            }
        }
        MedicalRecord medRecord = {id: recordId, ...recordEntry};
        lock {
            recordTable.put(medRecord.clone());
        }
        return medRecord;
    }

    # Delete a record by ID
    #
    # + return - returns can be any of following types 
    # http:NoContent (Medical record deleted successfully)
    # http:NotFound (Medical record not found)
    isolated resource function delete records/[string recordId]() returns MedicalRecord|http:NotFound {
        lock {
            if !recordTable.hasKey(recordId) {
                return {body: "Medical record not found"};
            }
            return recordTable.remove(recordId).clone();
        }
    }

    # Get medical records for a Patient ID
    #
    # + return - returns can be any of following types 
    # http:Ok (MedicalRecord details)
    # http:NotFound (Patient not found)
    isolated resource function get recordsByPatient/[string patientId]() returns MedicalRecord[]|http:NotFound {
        lock {
            if !patientTable.hasKey(patientId) {
                return {body: "Patient not found"};
            }
        }
        lock {
            return recordTable.filter((medRecord) => medRecord.patientId == patientId).toArray().clone();
        }
    }
}
