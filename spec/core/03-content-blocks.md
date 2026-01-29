# Content Blocks

**Section**: Core Specification
**Version**: 0.1

## 1. Overview

The content layer represents document content as a tree of semantic blocks. This approach:

- Separates meaning from presentation
- Enables consistent editing across implementations
- Supports reliable machine extraction
- Facilitates accessibility

## 2. Content File

### 2.1 Location and Format

The content file:

- MUST be located at `content/document.json` (or path specified in manifest)
- MUST be valid JSON conforming to [RFC 8259](https://www.rfc-editor.org/rfc/rfc8259)
- MUST be encoded as UTF-8 without BOM

### 2.2 Root Structure

```json
{
  "version": "0.1",
  "blocks": [
    { "type": "heading", "level": 1, "children": [...] },
    { "type": "paragraph", "children": [...] },
    ...
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Content model version |
| `blocks` | array | Yes | Array of block objects |

## 3. Block Model

### 3.1 Block Object

Every block has the following base structure:

```json
{
  "type": "paragraph",
  "id": "block-123",
  "children": [...],
  "attributes": {}
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Block type identifier |
| `id` | string | No | Unique block identifier within document |
| `children` | array | Varies | Child nodes (blocks or text) |
| `attributes` | object | No | Type-specific attributes |

### 3.2 Block Identifiers

Block IDs:

- MUST be unique within the document
- SHOULD be present on all blocks
- MUST be present when the document uses any extension that references content positions (collaboration, phantoms, semantic, presentation extension)
- MUST be stable across edits for documents in REVIEW or later states
- SHOULD be stable across edits in DRAFT state (for collaboration)
- SHOULD use URL-safe characters

Block IDs share the document-wide ID namespace with named anchor IDs (see Anchors and References specification). Block IDs and anchor IDs MUST be unique across both sets.

## 4. Core Block Types

### 4.1 Text Leaf Nodes

Text nodes are the leaf nodes that contain actual text content.

```json
{
  "type": "text",
  "value": "Hello, world",
  "marks": ["bold", "italic"]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Always "text" |
| `value` | string | Yes | Text content |
| `marks` | array | No | Formatting marks |

#### 4.1.1 Standard Marks

| Mark | Description |
|------|-------------|
| `bold` | Bold/strong text |
| `italic` | Italic/emphasized text |
| `underline` | Underlined text |
| `strikethrough` | Struck-through text |
| `code` | Inline code (monospace) |
| `superscript` | Superscript text |
| `subscript` | Subscript text |
| `anchor` | Named anchor point (see below and Anchors and References spec) |

#### 4.1.1a Anchor Mark

The `anchor` mark places a named, stable anchor point within text. Anchor marks enable internal references that survive content edits.

```json
{
  "type": "text",
  "value": "key concept",
  "marks": [
    { "type": "anchor", "id": "def-key-concept" }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Always `"anchor"` |
| `id` | string | Yes | Unique anchor identifier (shares namespace with block IDs) |

See the Anchors and References specification for full details on the anchor system, including Content Anchor URIs, character offset computation, and validation rules.

#### 4.1.2 Link Mark

Links use an extended mark format:

```json
{
  "type": "text",
  "value": "click here",
  "marks": [
    {
      "type": "link",
      "href": "https://example.com",
      "title": "Example Site"
    }
  ]
}
```

The `href` field also accepts Content Anchor URIs for internal links. Values beginning with `#` are interpreted as internal references:

```json
{
  "type": "text",
  "value": "See the introduction",
  "marks": [
    {
      "type": "link",
      "href": "#intro",
      "title": "Introduction"
    }
  ]
}
```

See the Anchors and References specification for the full Content Anchor URI syntax.

### 4.2 Paragraph

Standard paragraph block.

```json
{
  "type": "paragraph",
  "children": [
    { "type": "text", "value": "This is a paragraph with " },
    { "type": "text", "value": "bold", "marks": ["bold"] },
    { "type": "text", "value": " text." }
  ]
}
```

Children: Text nodes only

### 4.3 Heading

Section heading with level.

```json
{
  "type": "heading",
  "level": 2,
  "children": [
    { "type": "text", "value": "Section Title" }
  ]
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `level` | integer | Yes | Heading level (1-6) |

Children: Text nodes only

### 4.4 List

Ordered or unordered list.

```json
{
  "type": "list",
  "ordered": true,
  "start": 1,
  "children": [
    {
      "type": "listItem",
      "children": [
        { "type": "paragraph", "children": [...] }
      ]
    }
  ]
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `ordered` | boolean | Yes | Whether list is ordered |
| `start` | integer | No | Starting number (ordered lists only) |

Children: `listItem` blocks only

### 4.5 List Item

Individual list item (only valid as child of list).

```json
{
  "type": "listItem",
  "checked": null,
  "children": [
    { "type": "paragraph", "children": [...] }
  ]
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `checked` | boolean\|null | No | Checkbox state (null = not a checkbox) |

Children: Paragraph, list, or other block-level content

### 4.6 Blockquote

Quoted content block.

```json
{
  "type": "blockquote",
  "children": [
    { "type": "paragraph", "children": [...] }
  ]
}
```

Children: Paragraph or other block-level content

### 4.7 Code Block

Block of source code or preformatted text.

```json
{
  "type": "codeBlock",
  "language": "javascript",
  "children": [
    { "type": "text", "value": "function hello() {\n  return 'world';\n}" }
  ]
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `language` | string | No | Programming language identifier |

Children: Single text node (no marks)

Language identifiers SHOULD follow common conventions (e.g., "javascript", "python", "rust").

### 4.8 Horizontal Rule

Thematic break between sections.

```json
{
  "type": "horizontalRule"
}
```

Children: None (void element)

### 4.9 Image

Embedded or referenced image.

```json
{
  "type": "image",
  "src": "assets/images/figure1.png",
  "alt": "Diagram showing system architecture",
  "title": "Figure 1: System Architecture",
  "width": 800,
  "height": 600
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `src` | string | Yes | Image source (path or URL) |
| `alt` | string | Yes | Alternative text (accessibility) |
| `title` | string | No | Image title/caption |
| `width` | integer | No | Intrinsic width in pixels |
| `height` | integer | No | Intrinsic height in pixels |

Children: None (void element)

For embedded images, `src` MUST be a relative path within the archive (e.g., `assets/images/figure1.png`).

### 4.10 Table

Tabular data.

```json
{
  "type": "table",
  "children": [
    {
      "type": "tableRow",
      "header": true,
      "children": [
        { "type": "tableCell", "children": [{ "type": "text", "value": "Name" }] },
        { "type": "tableCell", "children": [{ "type": "text", "value": "Value" }] }
      ]
    },
    {
      "type": "tableRow",
      "children": [
        { "type": "tableCell", "children": [{ "type": "text", "value": "Foo" }] },
        { "type": "tableCell", "children": [{ "type": "text", "value": "42" }] }
      ]
    }
  ]
}
```

Children: `tableRow` blocks only

### 4.11 Table Row

Row within a table.

```json
{
  "type": "tableRow",
  "header": false,
  "children": [...]
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `header` | boolean | No | Whether row is a header row |

Children: `tableCell` blocks only

### 4.12 Table Cell

Cell within a table row.

```json
{
  "type": "tableCell",
  "colspan": 1,
  "rowspan": 1,
  "align": "left",
  "children": [...]
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `colspan` | integer | No | Number of columns to span (default: 1) |
| `rowspan` | integer | No | Number of rows to span (default: 1) |
| `align` | string | No | Text alignment: "left", "center", "right" |

Children: Text nodes or block-level content

### 4.13 Math

Mathematical content using MathML or LaTeX.

```json
{
  "type": "math",
  "display": true,
  "format": "latex",
  "value": "E = mc^2"
}
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `display` | boolean | Yes | Display mode (true) vs inline (false) |
| `format` | string | Yes | `"latex"` or `"mathml"` |
| `value` | string | Yes | Math content in specified format |

**Format details:**
- `"latex"` — LaTeX math mode using amsmath package conventions. Content is the expression only (no `$` or `\begin{equation}` delimiters). Example: `"E = mc^2"`, `"\\frac{1}{2}"`, `"\\sum_{i=1}^{n} x_i"`
- `"mathml"` — MathML 3.0 (W3C Recommendation). Content is the `<math>` element body

Children: None (content in `value` attribute)

### 4.14 Break

Line break within a block.

```json
{
  "type": "break"
}
```

Children: None (void element)

Used for hard line breaks within paragraphs.

## 5. Extension Block Types

Extensions MAY define additional block types. Extension blocks:

- MUST use a namespaced type (e.g., `"forms:input"`)
- SHOULD define fallback rendering for non-supporting implementations
- MUST be documented in the extension specification

Example:

```json
{
  "type": "forms:textInput",
  "name": "email",
  "label": "Email Address",
  "required": true,
  "fallback": {
    "type": "paragraph",
    "children": [{ "type": "text", "value": "[Email input field]" }]
  }
}
```

## 6. Internationalization

### 6.1 Text Direction

Blocks MAY specify text direction:

```json
{
  "type": "paragraph",
  "attributes": {
    "dir": "rtl",
    "lang": "ar"
  },
  "children": [...]
}
```

| Attribute | Type | Description |
|-----------|------|-------------|
| `dir` | string | Text direction: "ltr", "rtl", "auto" |
| `lang` | string | BCP 47 language tag |

### 6.2 Unicode

All text content MUST be valid Unicode (UTF-8 encoded in JSON). Implementations MUST support:

- All Unicode normalization forms
- Bidirectional text
- Combining characters
- Emoji

## 7. Validation

### 7.1 Structural Rules

1. Blocks MUST have a valid `type`
2. Children MUST be appropriate for the block type
3. Required attributes MUST be present
4. Text nodes MUST have non-null `value`

### 7.2 Content Rules

1. Paragraph children MUST be text nodes
2. Heading children MUST be text nodes
3. List children MUST be listItem blocks
4. Table children MUST be tableRow blocks
5. TableRow children MUST be tableCell blocks

### 7.3 Cross-References

Image `src` attributes that reference embedded assets MUST correspond to files in the assets directory.

## 8. Processing Model

### 8.1 Parsing

1. Parse JSON
2. Validate root structure
3. Recursively validate blocks
4. Resolve asset references

### 8.2 Serialization

1. Construct block tree
2. Assign IDs if needed
3. Serialize to JSON
4. Compute hash for manifest

### 8.3 Normalization

Before comparison or hashing, content SHOULD be normalized:

1. Sort object keys alphabetically
2. Remove empty attributes
3. Collapse adjacent text nodes with same marks
4. Normalize Unicode to NFC form

## 9. Examples

### 9.1 Simple Document

```json
{
  "version": "0.1",
  "blocks": [
    {
      "type": "heading",
      "level": 1,
      "children": [{ "type": "text", "value": "Introduction" }]
    },
    {
      "type": "paragraph",
      "children": [
        { "type": "text", "value": "This document describes the " },
        { "type": "text", "value": "Codex", "marks": ["bold"] },
        { "type": "text", "value": " format." }
      ]
    },
    {
      "type": "list",
      "ordered": false,
      "children": [
        {
          "type": "listItem",
          "children": [
            {
              "type": "paragraph",
              "children": [{ "type": "text", "value": "Semantic-first design" }]
            }
          ]
        },
        {
          "type": "listItem",
          "children": [
            {
              "type": "paragraph",
              "children": [{ "type": "text", "value": "Modern security" }]
            }
          ]
        }
      ]
    }
  ]
}
```

### 9.2 Document with Table and Image

```json
{
  "version": "0.1",
  "blocks": [
    {
      "type": "heading",
      "level": 1,
      "children": [{ "type": "text", "value": "Results" }]
    },
    {
      "type": "image",
      "src": "assets/images/chart.png",
      "alt": "Bar chart showing quarterly results",
      "title": "Figure 1: Quarterly Results"
    },
    {
      "type": "table",
      "children": [
        {
          "type": "tableRow",
          "header": true,
          "children": [
            { "type": "tableCell", "children": [{ "type": "text", "value": "Quarter" }] },
            { "type": "tableCell", "children": [{ "type": "text", "value": "Revenue" }] }
          ]
        },
        {
          "type": "tableRow",
          "children": [
            { "type": "tableCell", "children": [{ "type": "text", "value": "Q1" }] },
            { "type": "tableCell", "children": [{ "type": "text", "value": "$1.2M" }] }
          ]
        }
      ]
    }
  ]
}
```
