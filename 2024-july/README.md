# Ballerina Tech Talk - July 2024

_Topic_: **Beyond CLI Basics: Using Extended Ballerina CLI Tools for Powerful Integrations** \
_Date_: 2024-07-11 \
_Presenter_: [@GayalDassanayake](https://github.com/gayaldassanayake) \
_Link_: [YouTube](https://www.youtube.com/watch?v=TZQWfA0v4cw)

> The below code samples use Ballerina Swan Lake Update 9 (2201.9.2)

## Demonstration 1: `bal tool` Command

In this section we review the `bal tool` command functionality shown in the first demonstration of the tech talk.

`bal tool` has a set of sub-commands that allow managing the tool life cycle.

### `bal tool search`

The `bal tool search` command is used to search for tool information in [the Ballerina Central](https://central.ballerina.io/).

Run `bal tool search` to search for the `health` tool. The `health` tool generates Ballerina code for developing healthcare integrations.

```
$ bal tool search health

Ballerina Central
=================

|ID                 |PACKAGE           |DESCRIPTION                               |DATE            |VERSION       |
|-------------------|------------------|------------------------------------------|----------------|--------------|
|health             |ballerinax/health |This project contains an extension imp... |2024-05-07-Tue  |2.1.2         |

1 tools found.
```

The latest version of the `health` tool is `2.1.2`.

### `bal tool pull`

Pull the `health` tool to the local machine.
```
$ bal tool pull health
ballerinax/health:2.1.2 [central.ballerina.io ->/Users/gayaldassanayake/.ballerina/repositories/central.ballerina.io/bala/ballerinax/health/2.1.2]  100% [=====================] 93313/93313 KB (0:00:08 / 0:00:00)
ballerinax/health:2.1.2 pulled from central successfully

tool 'health:2.1.2' pulled successfully.
tool 'health:2.1.2' successfully set as the active version.
```

Alternatively, we can specify a version to pull a specific version of the tool.

```
$ bal tool pull health:2.1.1
ballerinax/health:2.1.1 [central.ballerina.io ->/Users/gayaldassanayake/.ballerina/repositories/central.ballerina.io/bala/ballerinax/health/2.1.1]  100% [=====================] 93539/93539 KB (0:00:13 / 0:00:00)
ballerinax/health:2.1.1 pulled from central successfully

tool 'health:2.1.1' pulled successfully.
tool 'health:2.1.1' successfully set as the active version.
```

### `bal tool list`

The `bal tool list` command lists the tools that are installed in the local machine.

```
$ bal tool list
|TOOL ID               |VERSION         |REPO       |
|----------------------|----------------|-----------|
|health                |  2.1.2         |central    |
|health                |* 2.1.1         |central    |

2 tools found.
```

### `bal help`

To make sure that the tool is installed, type `bal help`.

``` bash
$ bal help
NAME
       The build system and package manager of Ballerina

SYNOPSIS
       bal <command> [args]
       bal [OPTIONS]


OPTIONS
       # removed for brevity


COMMANDS
        The available subcommands are:

   # removed for brevity

   Tool Commands:
        health          Ballerina Health Artifact Generator Tool
    
   # removed for brevity

Use 'bal help <command>' for more information on a specific command.
```

We can use `bal help health` to get more information about the `health` tool.

### `bal tool use`

The `bal tool use` command is used to set the active version of the tool.

```
$ bal tool use health:2.1.2
tool 'health:2.1.2' successfully set as the active version.
bal tool use health:2.1.1
$ bal tool use health:2.1.1
tool 'health:2.1.1' successfully set as the active version.
```

### `bal tool remove`

The `bal tool remove` command is used to remove a tool from the local machine.

```
$ bal tool remove health:2.1.2
tool 'health:2.1.2' successfully removed.
```

### `bal tool update`

The `bal tool update` command is used to update the tool to the latest version.

```
$ bal tool update health
ballerinax/health:2.1.2 [central.ballerina.io ->/Users/gayaldassanayake/.ballerina/repositories/central.ballerina.io/bala/ballerinax/health/2.1.2]  100% [=====================] 94018/94018 KB (0:00:52 / 0:00:00)
ballerinax/health:2.1.2 pulled from central successfully

tool 'health:2.1.2' pulled successfully.
tool 'health:2.1.2' successfully set as the active version.
```

## Demonstration 2: EDI tool

### Prerequisites

Install the Ballerina EDI tool with `bal tool pull edi`.

### Implementation

1. Generate the Ballerina EDI schemas for the X12 `inventory` and `purchase order` schemas in the `x12-schemas` directory.

```
$ bal edi convertX12Schema -i x12-schemas/invoice.xsd -o ballerina-schemas/invoice.json
$ bal edi convertX12Schema -i x12-schemas/purchaseorder.xsd -o ballerina-schemas/purchaseorder.json
```

2. Generate a Ballerina package with utilities to parse invoice and purchase order EDI documents.

```
$ bal edi libgen -p aerospace/inventory -i ballerina-schemas -o .
```

3. Navigate to the generated inventory package.
```
$ cd inventory
```

4. Pack the generated package.

```
$ bal pack
Compiling source
        aerospace/inventory:0.1.0

Creating bala
        target/bala/aerospace-inventory-any-0.1.0.bala
```

5.  Push it to the local repository to be used in a user package.

```
$ bal push --repository=local
Successfully pushed target/bala/aerospace-inventory-any-0.1.0.bala to 'local' repository.
```

6. Navigate to the `inventory-user` package.

```
$ cd ../inventory-user
```

7. In the `main.bal` file of the `inventory-user` package, we can read the sample purchase order in the 
`inventory-user/resources/po_11_06_2024.edi` file and extract information to create an invoice as below.

``` ballerina
// main.bal
string ediText = check io:fileReadString("./resources/po_11_06_2024.edi");
mpurchaseorder:EDI_purchaseorder_X12_005020_850 purchaseOrder = check mpurchaseorder:fromEdiString(ediText);
// getInvoiceFromPurchaseOrder converts the purchaseOrder record into an invoice record
minvoice:EDI_invoice_X12_005020_810 invoice = getInvoiceFromPurchaseOrder(purchaseOrder);
check io:fileWriteString("target/invoice.edi", check minvoice:toEdiString(invoice));
```
 
8. Execute the above code to generate an invoice corresponding to the purchase order.

```
$ bal run
```

``` edi
ST*810*0001~
BIG*2024-07-17T12:02:21.061347Z*3800155417489605195~
IT1*ITM0145*908*KG*50.00*KG*BP*34098~
IT1*ITM3487*34*EA*2345.89*PE*BP*67890~
```

## Demonstration 3: Openapi tool integration with package build

1. Generate OpenAPI specifications for `hospital-service/hospital_service.bal` and `hospital-service/support_service.bal` 
using the `openapi` tool. The generated OpenAPI specifications now reside in the resources directory.

``` bash
$ bal openapi -i hospital-service/hospital_service.bal -o resources  
OpenAPI definition(s) generated successfully and copied to :
-- hospital_openapi.yaml
$ bal openapi -i hospital-service/support_service.bal -o resources 
OpenAPI definition(s) generated successfully and copied to :
-- hospital_support_openapi.yaml 
```

2. With the OpenAPI specifications, we can generate a client, by integrating the `openapi` tool with the package build.
First, create a new package `hospital-client`.

```
$ bal new hospital-client -t lib
```

3. In the `Ballerina.toml`, add two new entries to generate the clients for the `hospital_service` and the `support_service`.

``` toml
[[tool.openapi]]
id = "hospital-client"
filePath = "../resources/hospital_openapi.yaml"
options.license = "../resources/wso2-license.txt"

[[tool.openapi]]
id = "support-client"
filePath = "../resources/hospital_support_openapi.yaml"
targetModule = "support"
```

4. Run the `bal pack` command on the generated client package.

```
$ cd hospital-client
$ bal pack

Executing Build Tools
        openapi(hospital-client)
        openapi(support-client)

Compiling source
        gayaldassanayake/hospital_client:0.1.0

Creating bala
        target/bala/gayaldassanayake-hospital_client-any-0.1.0.bala
```

5. Push the packed .bala file to the local repository.

```
% bal push --repository=local                
Successfully pushed target/bala/gayaldassanayake-hospital_client-any-0.1.0.bala to 'local' repository.
```

6. In the `hospital-user` package `main.bal`, add the following code to register a new patient in the system, and 
add a new medical record for the patient.

``` ballerina
// Create a new hospital client instance
hospital_client:Client hClient = check new hospital_client:Client(serviceUrl = "http://localhost:9090/hospital");
// Register a patient
hospital_client:PatientEntry patientEntry = {
    firstName: "Max",
    lastName: "Fenton",
    gender: "male",
    dob: {year: 1990, month: 10, day: 10}
};
hospital_client:Patient patient = check hClient->/patients.post(patientEntry);
// Register a medical record for the patient
hospital_client:MedicalRecordEntry medicalRecordEntry = {
    patientId: patient.id,
    description: "Skin desease",
    date: {year: 2024, month: 7, day: 11}
};
hospital_client:MedicalRecord medicalRecord = check hClient->/records.post(medicalRecordEntry);
io:println(string `Medical record ${medicalRecord.id} created for the patient ${patient.id}`);
```

7. Start the `hospital-service`.

```
$ bal run hospital-service
Compiling source
        gayaldassanayake/hospital_service:0.1.0

Running executable
```

8. Execute the `hospital-user`.

```
$ bal run hospital-user 
Compiling source
        gayaldassanayake/hospital_user:0.1.0

Running executable

Medical record c4419dad-debb-469d-bade-1c894d3cab75 created for the patient 1b01848b-ab5e-456c-927a-45aa58d9dd8f
```
