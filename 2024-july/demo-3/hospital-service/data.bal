isolated final table<Patient> key(id) patientTable = table [
    {id: "a0384c7b-d22b-4627-9a2d-dfce02987c96", firstName: "John", lastName: "Doe", dob: {year: 1954, month: 10, day: 23}, gender: "male"},
    {id: "722d6531-a9f3-4eb7-8735-aa7151f9bb39", firstName: "Jane", lastName: "Doe", dob: {year: 1972, month: 9, day: 17}, gender: "female"},
    {id: "3830b911-6e15-4fcf-bc9a-5d1f238fd27d", firstName: "Matthew", lastName: "Moore", dob: {year: 1988, month: 3, day: 5}, gender: "male"}
];

isolated table<MedicalRecord> key(id) recordTable = table [
    {id: "b43934c3-48c2-4856-9a4d-82628b55cc26", patientId: "a0384c7b-d22b-4627-9a2d-dfce02987c96", date: {year: 2020, month: 10, day: 23}, description: "Severe headache and fever. Prescribed paracetamol."},
    {id: "f694685c-9401-4314-af73-a0be5e46731a", patientId: "722d6531-a9f3-4eb7-8735-aa7151f9bb39", date: {year: 2020, month: 10, day: 23}, description: "Asthma attack. Prescribed Ventolin."},
    {id: "5a1fa822-6f5a-4c47-b6f3-6d33e4d347dc", patientId: "3830b911-6e15-4fcf-bc9a-5d1f238fd27d", date: {year: 2020, month: 10, day: 23}, description: "Fractured arm. Referred to orthopedic."},
    {id: "09e3ad2c-55b5-471c-8b23-cc4ece4c9045", patientId: "a0384c7b-d22b-4627-9a2d-dfce02987c96", date: {year: 2020, month: 10, day: 24}, description: "Fever subsided. Advised to rest."}
];

isolated table<Employee> key(id) employeeTable = table [
    {id : "eac79686-4c9e-4b27-b921-471024603712", firstName: "Aaron", lastName: "Hite", designation: "doctor"},
    {id : "6ea48199-78e1-4c40-8a26-12862f6fe605", firstName: "Larry", lastName: "King", designation: "nurse"}
];

isolated table<InventoryItem> key(id) inventoryItemTable = table [
    {id: "b1b3b3b3-1b3b-1b3b-1b3b-1b3b3b3b3b3b", name: "Paracetamol", description: "Fever and pain relief", quantity: 100},
    {id: "748f3886-33da-43a7-abfc-d3042ac59fec", name: "Ventolin", description: "Asthma relief", quantity: 50},
    {id: "2fcd37b3-e219-4db0-aba7-83ad52b2bba7", name: "Saline", description: "IV fluid", quantity: 200}
];
