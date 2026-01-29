# Presentation Layers

**Section**: Core Specification
**Version**: 0.1

## 1. Overview

Presentation layers define how semantic content is rendered visually. Multiple presentation layers enable the same content to be displayed differently depending on context (print, screen, responsive).

The key principle: **Content is authoritative; presentation is derived.**

## 2. Design Philosophy

### 2.1 Separation of Concerns

```
CONTENT (Semantic)          PRESENTATION (Visual)
├── What the text says      ├── How it looks
├── Document structure      ├── Layout and positioning
├── Meaning and intent      ├── Typography choices
└── Machine-readable        └── Human-optimized
```

### 2.2 Presentation Types

| Type | Use Case | Characteristics |
|------|----------|-----------------|
| `paginated` | Print, PDF export | Fixed pages, precise positioning |
| `continuous` | Screen reading | Vertical scroll, no page breaks |
| `responsive` | Multi-device | Adapts to viewport size |

## 3. Presentation and Document State

### 3.1 State-Aware Progressive Enhancement

Presentation precision evolves with document maturity. The presentation layer follows a progressive enhancement model tied to document state:

| Document State | Presentation Requirement | Rationale |
|----------------|-------------------------|-----------|
| **DRAFT** | Reactive only | Content is fluid, layout doesn't matter yet |
| **REVIEW** | Reactive (precise optional) | Reviewers see approximate pagination |
| **FROZEN** | Reactive + **precise required** | Layout becomes part of immutable record |
| **PUBLISHED** | Same as FROZEN | Authoritative appearance, pixel-perfect |

### 3.2 Why State-Awareness Matters

1. **Provenance integrity** — When frozen, the precise layout is immutable alongside the content. The document ID covers semantic content; use scoped signatures (Security Extension) for appearance attestation
2. **Legal/academic needs** — Citations reference "page 7, line 23" with confidence
3. **Lifecycle alignment** — Precision emerges naturally as documents mature
4. **No capability loss** — Semantic content always present for accessibility/search
5. **Stable cross-references** — Internal refs ("see page 7") guaranteed stable once frozen

### 3.3 Reactive vs. Precise Presentation

**Reactive presentation** (paginated, continuous, responsive) provides hints and styles that renderers interpret. The same document may render differently across devices or implementations.

**Precise presentation** (layouts) provides exact coordinates for every element. The document renders identically everywhere.

### 3.4 Transition Requirements

When transitioning to FROZEN or PUBLISHED state:

1. At least one precise layout MUST exist
2. The layout's `contentHash` MUST match current content hash
3. If layout is stale, transition MUST fail

This ensures that when a document is "frozen," its appearance is frozen too.

## 4. Presentation File Structure

### 4.1 Location

Presentation files are stored in the `presentation/` directory:

```
presentation/
├── paginated.json        # Reactive: print/PDF hints
├── continuous.json       # Reactive: scroll layout hints
├── responsive.json       # Reactive: viewport adaptation
└── layouts/              # Precise: exact coordinates
    ├── letter.json       # Required for FROZEN/PUBLISHED
    └── a4.json           # Additional formats (optional)
```

### 4.2 Root Structure

```json
{
  "version": "0.1",
  "type": "paginated",
  "defaults": {...},
  "pages": [...],
  "styles": {...}
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Presentation format version |
| `type` | string | Yes | Presentation type identifier |
| `defaults` | object | Yes | Default styling values |
| `pages` | array | Varies | Page definitions (paginated only) |
| `styles` | object | Yes | Style definitions |

## 5. Styling Model

### 5.1 CSS Subset

Presentation styling uses a subset of CSS properties. This provides familiarity while constraining complexity.

#### 4.1.1 Supported Properties

**Typography:**
- `fontFamily` - Font family stack
- `fontSize` - Font size (with units)
- `fontWeight` - Font weight (100-900 or keywords)
- `fontStyle` - normal, italic
- `lineHeight` - Line height (unitless ratio or with units)
- `letterSpacing` - Letter spacing
- `textAlign` - left, center, right, justify
- `textDecoration` - none, underline, line-through
- `textTransform` - none, uppercase, lowercase, capitalize
- `color` - Text color

**Spacing:**
- `marginTop`, `marginRight`, `marginBottom`, `marginLeft`
- `paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft`

**Borders:**
- `borderWidth`, `borderStyle`, `borderColor`
- Individual sides: `borderTopWidth`, etc.

**Background:**
- `backgroundColor`

**Layout:**
- `width`, `height`, `maxWidth`, `maxHeight`
- `display` - block, inline, none

### 5.2 Units

Supported units:

| Unit | Description | Use |
|------|-------------|-----|
| `px` | Pixels (72 per inch for print) | Absolute sizing |
| `pt` | Points (1/72 inch) | Typography |
| `em` | Relative to font size | Responsive sizing |
| `rem` | Relative to root font size | Consistent sizing |
| `%` | Percentage of container | Relative layout |
| `in` | Inches | Print layout |
| `cm` | Centimeters | Print layout |
| `mm` | Millimeters | Print layout |

### 5.3 Colors

Colors may be specified as:

- Named colors: `"red"`, `"blue"`, `"black"`, etc.
- Hex: `"#ff0000"`, `"#f00"`
- RGB: `"rgb(255, 0, 0)"`
- RGBA: `"rgba(255, 0, 0, 0.5)"`

## 6. Paginated Presentation

### 6.1 Structure

```json
{
  "version": "0.1",
  "type": "paginated",
  "defaults": {
    "pageSize": "letter",
    "orientation": "portrait",
    "margins": {
      "top": "1in",
      "right": "1in",
      "bottom": "1in",
      "left": "1in"
    }
  },
  "pages": [
    {
      "number": 1,
      "elements": [...]
    }
  ],
  "styles": {...}
}
```

### 6.2 Page Sizes

| Name | Dimensions | Use |
|------|------------|-----|
| `letter` | 8.5 × 11 in | US standard |
| `legal` | 8.5 × 14 in | US legal |
| `a4` | 210 × 297 mm | International standard |
| `a5` | 148 × 210 mm | Half A4 |
| Custom | `{ "width": "8in", "height": "10in" }` | Any size |

### 6.3 Page Elements

Each page contains positioned elements that reference content blocks:

```json
{
  "number": 1,
  "elements": [
    {
      "blockId": "block-123",
      "position": {
        "x": "1in",
        "y": "1in",
        "width": "6.5in",
        "height": "auto"
      },
      "style": "heading1"
    },
    {
      "blockId": "block-456",
      "position": {
        "x": "1in",
        "y": "2in",
        "width": "6.5in",
        "height": "auto"
      },
      "style": "bodyText"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `blockId` | string | Yes | Reference to content block ID |
| `position` | object | Yes | Position and size |
| `style` | string | No | Named style to apply |
| `overflow` | string | No | "visible", "hidden", "flow" |

### 6.4 Flow Elements

For automatic text flow across pages:

```json
{
  "type": "flow",
  "blockIds": ["block-1", "block-2", "block-3"],
  "columns": 1,
  "startPage": 1,
  "regions": [
    {
      "page": 1,
      "position": { "x": "1in", "y": "2in", "width": "6.5in", "height": "8in" }
    },
    {
      "page": 2,
      "position": { "x": "1in", "y": "1in", "width": "6.5in", "height": "9in" }
    }
  ]
}
```

## 7. Continuous Presentation

### 7.1 Structure

```json
{
  "version": "0.1",
  "type": "continuous",
  "defaults": {
    "maxWidth": "800px",
    "padding": "24px"
  },
  "sections": [
    {
      "blockRefs": ["block-1", "block-2"],
      "style": "introduction"
    }
  ],
  "styles": {...}
}
```

### 7.2 Sections

Continuous presentation groups content into sections for styling purposes:

```json
{
  "blockRefs": ["block-1", "block-2", "block-3"],
  "style": "chapter",
  "attributes": {
    "marginTop": "48px",
    "borderTop": "1px solid #ccc"
  }
}
```

## 8. Responsive Presentation

### 8.1 Structure

```json
{
  "version": "0.1",
  "type": "responsive",
  "defaults": {
    "rootFontSize": "16px"
  },
  "breakpoints": [
    { "name": "mobile", "maxWidth": "599px" },
    { "name": "tablet", "minWidth": "600px", "maxWidth": "1023px" },
    { "name": "desktop", "minWidth": "1024px" }
  ],
  "styles": {
    "heading1": {
      "base": { "fontSize": "2rem", "fontWeight": "700" },
      "mobile": { "fontSize": "1.5rem" }
    }
  }
}
```

### 8.2 Breakpoints

```json
{
  "breakpoints": [
    { "name": "mobile", "maxWidth": "599px" },
    { "name": "tablet", "minWidth": "600px", "maxWidth": "1023px" },
    { "name": "desktop", "minWidth": "1024px" }
  ]
}
```

### 8.3 Responsive Styles

Styles can have breakpoint-specific overrides:

```json
{
  "paragraph": {
    "base": {
      "fontSize": "1rem",
      "lineHeight": 1.6,
      "marginBottom": "1em"
    },
    "mobile": {
      "fontSize": "0.9rem",
      "lineHeight": 1.5
    },
    "desktop": {
      "fontSize": "1.1rem"
    }
  }
}
```

## 9. Style Definitions

### 9.1 Named Styles

Styles are defined by name and referenced by elements:

```json
{
  "styles": {
    "heading1": {
      "fontFamily": "Georgia, serif",
      "fontSize": "2em",
      "fontWeight": "700",
      "marginTop": "1.5em",
      "marginBottom": "0.5em",
      "color": "#1a1a1a"
    },
    "bodyText": {
      "fontFamily": "system-ui, sans-serif",
      "fontSize": "1rem",
      "lineHeight": 1.6,
      "marginBottom": "1em",
      "color": "#333333"
    }
  }
}
```

### 9.2 Default Styles

Implementations MUST provide default styles for all block types when not explicitly styled.

Recommended defaults:

| Block Type | Font Size | Font Weight | Margins |
|------------|-----------|-------------|---------|
| heading1 | 2em | 700 | 0.67em top/bottom |
| heading2 | 1.5em | 700 | 0.83em top/bottom |
| heading3 | 1.17em | 700 | 1em top/bottom |
| paragraph | 1em | 400 | 1em bottom |
| list | 1em | 400 | 1em bottom |
| codeBlock | 0.9em | 400 | 1em top/bottom |

### 9.3 Style Inheritance

Styles can inherit from other styles:

```json
{
  "styles": {
    "baseText": {
      "fontFamily": "system-ui, sans-serif",
      "lineHeight": 1.6
    },
    "paragraph": {
      "extends": "baseText",
      "fontSize": "1rem",
      "marginBottom": "1em"
    },
    "lead": {
      "extends": "paragraph",
      "fontSize": "1.2rem",
      "fontWeight": "500"
    }
  }
}
```

## 10. Block Type Styling

### 10.1 Automatic Style Mapping

Content blocks are automatically mapped to styles:

| Block Type | Default Style Name |
|------------|-------------------|
| `heading` (level 1) | `heading1` |
| `heading` (level 2) | `heading2` |
| `heading` (level 3-6) | `heading3`-`heading6` |
| `paragraph` | `paragraph` |
| `list` | `list` |
| `listItem` | `listItem` |
| `blockquote` | `blockquote` |
| `codeBlock` | `codeBlock` |
| `table` | `table` |
| `image` | `image` |

### 10.2 Custom Block Styles

Content blocks can specify a custom style via their `style` attribute:

```json
{
  "type": "paragraph",
  "attributes": {
    "style": "lead"
  },
  "children": [...]
}
```

## 11. Presentation Caching

### 11.1 Cached vs. Computed

Presentation layers MAY be:

1. **Stored (cached)**: Pre-computed and saved in the document
2. **Computed**: Generated on-demand from content and styles

Recommendation:
- Store paginated presentation for print fidelity
- Compute continuous/responsive for flexibility

### 11.2 Cache Invalidation

When content changes, cached presentation layers become stale.

The manifest's content hash can be compared to detect staleness:

```json
{
  "presentation": [
    {
      "type": "paginated",
      "path": "presentation/paginated.json",
      "contentHash": "sha256:abc123...",
      "generated": "2025-01-15T10:00:00Z"
    }
  ]
}
```

If `contentHash` doesn't match current content hash, the presentation should be regenerated.

## 12. Precise Layouts

Precise layouts provide exact coordinates for every element, enabling pixel-perfect reproduction regardless of rendering implementation. They are **required** for FROZEN and PUBLISHED documents.

### 12.1 Location

Precise layouts are stored in `presentation/layouts/`:

```
presentation/
└── layouts/
    ├── letter.json       # US Letter format
    ├── a4.json           # A4 format
    └── legal.json        # US Legal format (if needed)
```

### 12.2 Precise Layout Structure

```json
{
  "version": "0.1",
  "presentationType": "precise",
  "targetFormat": "letter",
  "pageSize": {
    "width": "8.5in",
    "height": "11in"
  },
  "contentHash": "sha256:abc123...",
  "generatedAt": "2025-01-25T10:30:00Z",
  "pageTemplate": {
    "margins": { "top": "1in", "bottom": "1in", "left": "1in", "right": "1in" },
    "header": {
      "content": "Document Title",
      "style": "header",
      "y": "0.5in"
    },
    "footer": {
      "content": "Page {pageNumber} of {totalPages}",
      "style": "footer",
      "y": "10.5in"
    }
  },
  "pages": [...],
  "fonts": {...}
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Layout format version |
| `presentationType` | string | Yes | Must be `"precise"` |
| `targetFormat` | string | Yes | Page format name (letter, a4, legal, custom) |
| `pageSize` | object | Yes | Exact page dimensions |
| `contentHash` | string | Yes | Hash of content when layout was generated |
| `generatedAt` | string | Yes | ISO 8601 timestamp (when layout was generated — distinct from document `created`/`modified` which are lifecycle timestamps) |
| `pageTemplate` | object | No | Headers, footers, margins for all pages |
| `pages` | array | Yes | Array of page definitions |
| `fonts` | object | No | Font metrics for exact reproduction |

### 12.3 Page Definitions

Each page contains precisely positioned elements:

```json
{
  "pages": [
    {
      "number": 1,
      "elements": [
        {
          "blockId": "block-1",
          "x": "1in",
          "y": "1in",
          "width": "6.5in",
          "height": "0.5in"
        },
        {
          "blockId": "block-2",
          "x": "1in",
          "y": "1.75in",
          "width": "6.5in",
          "height": "2.3in",
          "continues": true
        }
      ]
    },
    {
      "number": 2,
      "elements": [
        {
          "blockId": "block-2",
          "x": "1in",
          "y": "1in",
          "width": "6.5in",
          "height": "1.2in",
          "continuation": true
        }
      ]
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `blockId` | string | Yes | Reference to content block ID |
| `x` | string | Yes | Horizontal position from left edge |
| `y` | string | Yes | Vertical position from top edge |
| `width` | string | Yes | Element width |
| `height` | string | Yes | Element height |
| `continues` | boolean | No | True if element continues to next page |
| `continuation` | boolean | No | True if element is continued from previous page |

### 12.4 Line-Level Precision

For legal documents requiring line citations ("page 7, line 23"), elements MAY include line-level coordinates:

```json
{
  "blockId": "block-5",
  "x": "1in",
  "y": "3in",
  "width": "6.5in",
  "height": "1.5in",
  "lines": [
    { "number": 1, "y": "3in", "height": "0.2in" },
    { "number": 2, "y": "3.25in", "height": "0.2in" },
    { "number": 3, "y": "3.5in", "height": "0.2in" }
  ]
}
```

Line-level precision is **optional** — only needed for legal/court documents where line numbers are referenced.

### 12.5 Font Metrics

For exact text reproduction, precise layouts MAY include font metrics:

```json
{
  "fonts": {
    "main": {
      "family": "Times New Roman",
      "style": "normal",
      "weight": 400,
      "unitsPerEm": 2048,
      "ascender": 1825,
      "descender": -443
    }
  }
}
```

Full font files (if needed) are stored in `assets/fonts/` and referenced from the asset index.

### 12.6 Content Hash Validation

The `contentHash` field enables staleness detection:

1. When generating a precise layout, record the current content hash
2. Before using a layout, compare its `contentHash` to current content
3. If they differ, the layout is **stale** and should not be used for frozen documents

```
Content Hash: sha256:abc123...
Layout Hash:  sha256:abc123...  ✓ Valid

Content Hash: sha256:xyz789...
Layout Hash:  sha256:abc123...  ✗ Stale - content has changed
```

### 12.7 Requirements by State

| State | Precise Layout Required | Staleness Check |
|-------|------------------------|-----------------|
| DRAFT | No | No |
| REVIEW | No | Optional |
| FROZEN | **Yes** | **Yes** (must match) |
| PUBLISHED | **Yes** | **Yes** (must match) |

## 13. Fallback Behavior

### 13.1 Missing Presentation

If no presentation layer is present:

1. Apply default styles to all blocks
2. Render in continuous vertical scroll
3. Use system fonts and sensible defaults

### 13.2 Unsupported Elements

For content blocks without styling rules:

1. Apply generic block styling
2. Log warning for implementers
3. Render content in fallback style

## 14. Print Considerations

### 14.1 Page Breaks

Control page breaks in paginated output:

```json
{
  "styles": {
    "chapter": {
      "pageBreakBefore": "always"
    },
    "heading2": {
      "pageBreakAfter": "avoid"
    }
  }
}
```

Values: `auto`, `always`, `avoid`

### 14.2 Headers and Footers

```json
{
  "pageTemplate": {
    "header": {
      "height": "0.5in",
      "content": {
        "left": { "text": "{title}" },
        "center": null,
        "right": { "text": "{date}" }
      }
    },
    "footer": {
      "height": "0.5in",
      "content": {
        "left": null,
        "center": { "text": "Page {pageNumber} of {pageCount}" },
        "right": null
      }
    }
  }
}
```

Variables:
- `{pageNumber}` - Current page number
- `{pageCount}` - Total page count
- `{title}` - Document title from metadata
- `{date}` - Current date
- `{author}` - Author from metadata

## 15. Accessibility

### 15.1 Requirements

Presentation layers MUST NOT:

- Hide content visually that should be accessible
- Use color alone to convey meaning
- Specify text smaller than reasonable minimum (12px recommended)

### 15.2 Contrast

For text colors, ensure sufficient contrast ratio:

- Normal text: 4.5:1 minimum
- Large text (18pt+ or 14pt+ bold): 3:1 minimum

## 16. Examples

### 16.1 Minimal Continuous Presentation

```json
{
  "version": "0.1",
  "type": "continuous",
  "defaults": {
    "maxWidth": "720px",
    "padding": "20px",
    "fontFamily": "Georgia, serif",
    "fontSize": "18px",
    "lineHeight": 1.7
  },
  "styles": {
    "heading1": {
      "fontSize": "2.5rem",
      "fontWeight": "700",
      "marginTop": "2rem",
      "marginBottom": "1rem"
    },
    "paragraph": {
      "marginBottom": "1.2em"
    }
  }
}
```

### 16.2 Print-Ready Paginated Presentation

```json
{
  "version": "0.1",
  "type": "paginated",
  "defaults": {
    "pageSize": "letter",
    "orientation": "portrait",
    "margins": {
      "top": "1in",
      "right": "1in",
      "bottom": "1in",
      "left": "1.25in"
    }
  },
  "pageTemplate": {
    "footer": {
      "height": "0.5in",
      "content": {
        "center": { "text": "{pageNumber}" }
      }
    }
  },
  "styles": {
    "heading1": {
      "fontFamily": "Helvetica, sans-serif",
      "fontSize": "24pt",
      "fontWeight": "700",
      "pageBreakBefore": "always"
    },
    "bodyText": {
      "fontFamily": "Times New Roman, serif",
      "fontSize": "12pt",
      "lineHeight": 1.5,
      "textAlign": "justify"
    }
  }
}
```
