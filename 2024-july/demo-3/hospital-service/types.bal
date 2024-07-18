public type Patient record {|
    readonly string id;
    *PatientEntry;
|};

public type PatientEntry record {|
    string firstName;
    string lastName;
    Date dob;
    string gender;
|};

public type MedicalRecord record {|
    readonly string id;
    *MedicalRecordEntry;
|};

public type MedicalRecordEntry record {|
    string patientId;
    Date date;
    string description;
|};

public type Employee record {|
    readonly string id;
    *EmployeeEntry;
|};

public type EmployeeEntry record {|
    string firstName;
    string lastName;
    string designation;
|};

public type InventoryItem record {|
    readonly string id;
    *InventoryItemEntry;
|};

public type InventoryItemEntry record {|
    string name;
    string description;
    int quantity;
|};

public type Date record {|
    int year;
    int month;
    int day;
|};
