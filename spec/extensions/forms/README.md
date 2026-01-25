# Forms Extension

**Extension ID**: `codex.forms`
**Version**: 0.1
**Status**: Draft

## 1. Overview

The Forms Extension enables interactive form fields within documents:

- Text inputs and text areas
- Checkboxes and radio buttons
- Dropdowns and date pickers
- Validation rules
- Form submission

## 2. Extension Declaration

```json
{
  "extensions": [
    {
      "id": "codex.forms",
      "version": "0.1",
      "required": false
    }
  ]
}
```

## 3. Form Block Types

### 3.1 Text Input

```json
{
  "type": "forms:textInput",
  "name": "fullName",
  "label": "Full Name",
  "placeholder": "Enter your name",
  "required": true,
  "maxLength": 100,
  "validation": {
    "pattern": "^[A-Za-z ]+$",
    "message": "Name must contain only letters and spaces"
  }
}
```

### 3.2 Text Area

```json
{
  "type": "forms:textArea",
  "name": "comments",
  "label": "Additional Comments",
  "rows": 4,
  "maxLength": 1000
}
```

### 3.3 Checkbox

```json
{
  "type": "forms:checkbox",
  "name": "agree",
  "label": "I agree to the terms and conditions",
  "required": true
}
```

### 3.4 Radio Group

```json
{
  "type": "forms:radioGroup",
  "name": "preference",
  "label": "Contact Preference",
  "options": [
    { "value": "email", "label": "Email" },
    { "value": "phone", "label": "Phone" },
    { "value": "mail", "label": "Postal Mail" }
  ],
  "required": true
}
```

### 3.5 Dropdown

```json
{
  "type": "forms:dropdown",
  "name": "country",
  "label": "Country",
  "options": [
    { "value": "us", "label": "United States" },
    { "value": "ca", "label": "Canada" },
    { "value": "uk", "label": "United Kingdom" }
  ],
  "searchable": true
}
```

### 3.6 Date Picker

```json
{
  "type": "forms:datePicker",
  "name": "birthDate",
  "label": "Date of Birth",
  "format": "YYYY-MM-DD",
  "minDate": "1900-01-01",
  "maxDate": "today"
}
```

### 3.7 Signature Field

```json
{
  "type": "forms:signature",
  "name": "signature",
  "label": "Signature",
  "required": true
}
```

## 4. Validation

### 4.1 Built-in Validators

| Validator | Description |
|-----------|-------------|
| `required` | Field must have a value |
| `minLength` | Minimum string length |
| `maxLength` | Maximum string length |
| `min` | Minimum numeric value |
| `max` | Maximum numeric value |
| `pattern` | Regular expression match |
| `email` | Valid email format |
| `url` | Valid URL format |

### 4.2 Custom Validation

```json
{
  "validation": {
    "custom": "value.length >= 8 && /[A-Z]/.test(value) && /[0-9]/.test(value)",
    "message": "Password must be at least 8 characters with uppercase and number"
  }
}
```

## 5. Form Data

### 5.1 Storage

Form values are stored in `forms/data.json`:

```json
{
  "version": "0.1",
  "values": {
    "fullName": "Jane Doe",
    "email": "jane@example.com",
    "country": "us"
  },
  "submitted": false,
  "lastModified": "2025-01-15T10:00:00Z"
}
```

### 5.2 Submission

```json
{
  "form": {
    "action": "https://api.example.com/submit",
    "method": "POST",
    "encoding": "application/json"
  }
}
```

## 6. Fallback Rendering

For viewers that don't support forms:

```json
{
  "type": "forms:textInput",
  "name": "email",
  "label": "Email",
  "fallback": {
    "type": "paragraph",
    "children": [
      { "type": "text", "value": "Email: _________________" }
    ]
  }
}
```

## 7. Examples

### 7.1 Contact Form

```json
{
  "type": "forms:form",
  "id": "contact-form",
  "children": [
    {
      "type": "forms:textInput",
      "name": "name",
      "label": "Name",
      "required": true
    },
    {
      "type": "forms:textInput",
      "name": "email",
      "label": "Email",
      "required": true,
      "validation": { "type": "email" }
    },
    {
      "type": "forms:textArea",
      "name": "message",
      "label": "Message",
      "required": true,
      "rows": 5
    },
    {
      "type": "forms:checkbox",
      "name": "subscribe",
      "label": "Subscribe to newsletter"
    },
    {
      "type": "forms:submit",
      "label": "Send Message"
    }
  ]
}
```
