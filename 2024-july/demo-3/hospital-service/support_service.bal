import ballerina/http;
import ballerina/uuid;

service /hospital\-support on hospitalEP {
    isolated resource function get employees() returns Employee[] {
        lock {
            return employeeTable.toArray().clone();
        }
    }

    isolated resource function get employees/[string employeeId]() returns Employee|http:NotFound {
        lock {
            if !employeeTable.hasKey(employeeId) {
                return {body: "Employee not found"};
            }
            return employeeTable.get(employeeId).clone();
        }
    }

    isolated resource function post employees(@http:Payload EmployeeEntry employeeEntry) returns Employee {
        Employee employee = {id: uuid:createRandomUuid(), ...employeeEntry};
        lock {
            employeeTable.put(employee.clone());
        }
        return employee;
    }

    isolated resource function put employees/[string employeeId](@http:Payload EmployeeEntry employeeEntry) returns Employee|http:NotFound {
        lock {
            if !employeeTable.hasKey(employeeId) {
                return {body: "Employee not found"};
            }
        }
        Employee employee = {id: employeeId, ...employeeEntry};
        lock {
            employeeTable.put(employee.clone());
        }
        return employee;
    }

    isolated resource function delete employees/[string employeeId]() returns Employee|http:NotFound {
        lock {
            if !employeeTable.hasKey(employeeId) {
                return {body: "Employee not found"};
            }
            return employeeTable.remove(employeeId).clone();
        }
    }

    isolated resource function get inventory\-items() returns InventoryItem[] {
        lock {
            return inventoryItemTable.toArray().clone();
        }
    }

    isolated resource function get inventory\-items/[string itemId]() returns InventoryItem|http:NotFound {
        lock {
            if !inventoryItemTable.hasKey(itemId) {
                return {body: "Inventory item not found"};
            }
            return inventoryItemTable.get(itemId).clone();
        }
    }

    isolated resource function post inventory\-items(@http:Payload InventoryItemEntry inventoryItemEntry) returns InventoryItem {
        InventoryItem inventoryItem = {id: uuid:createRandomUuid(), ...inventoryItemEntry};
        lock {
            inventoryItemTable.put(inventoryItem.clone());
        }
        return inventoryItem;
    }

    isolated resource function put inventory\-items/[string itemId](@http:Payload InventoryItemEntry inventoryItemEntry) returns InventoryItem|http:NotFound {
        lock {
            if !inventoryItemTable.hasKey(itemId) {
                return {body: "Inventory item not found"};
            }
        }
        InventoryItem inventoryItem = {id: itemId, ...inventoryItemEntry};
        lock {
            inventoryItemTable.put(inventoryItem.clone());
        }
        return inventoryItem;
    }

    isolated resource function delete inventory\-items/[string itemId]() returns InventoryItem|http:NotFound {
        lock {
            if !inventoryItemTable.hasKey(itemId) {
                return {body: "Inventory item not found"};
            }
            return inventoryItemTable.remove(itemId).clone();
        }
    }
}
