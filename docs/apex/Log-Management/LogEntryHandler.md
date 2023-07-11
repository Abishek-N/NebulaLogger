---
layout: default
---

## LogEntryHandler class

Manages setting fields on `LogEntry__c` before insert &amp; before update

---

### Properties

#### `code` → `String`

#### `endingLineNumber` → `Integer`

#### `startingLineNumber` → `Integer`

#### `targetLineNumber` → `Integer`

---

### Methods

#### `ApexCodeSnippet(ApexClass apexClass, Integer targetLineNumber)` → `public`

#### `getSObjectType()` → `Schema.SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

Schema.SObjectType

**Description**

The instance of `SObjectType`

---
