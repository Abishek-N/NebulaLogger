---
layout: default
---

## LogEntryMetadataViewerController class

Controller class for the LWC `logEntryMetadataViewer`

---

### Methods

#### `getMetadata(Id recordId)` → `LogEntryMetadata`

Returns an instance of the inner class `LogEntryMetadataViewerController.LogEntryMetadata`, which contains information about the log entry&apos;s origin and exception Apex classes

##### Parameters

| Param      | Description                          |
| ---------- | ------------------------------------ |
| `recordId` | The `ID` of the `LogEntry__c` record |

##### Return

**Type**

LogEntryMetadata

**Description**

An instance of `LogEntryMetadataViewerController.LogEntryMetadata`

---

### Inner Classes

#### LogEntryMetadataViewerController.LogEntryMetadata class

---

##### Properties

###### `exceptionApexClassCode` → `String`

###### `hasExceptionApexClassBeenModified` → `Boolean`

###### `hasOriginApexClassBeenModified` → `Boolean`

###### `originApexClassCode` → `String`

---
