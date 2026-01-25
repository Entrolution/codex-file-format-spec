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

## 3. Presentation File Structure

### 3.1 Location

Presentation files are stored in the `presentation/` directory:

```
presentation/
├── paginated.json
├── continuous.json
└── responsive.json
```

### 3.2 Root Structure

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

## 4. Styling Model

### 4.1 CSS Subset

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

### 4.2 Units

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

### 4.3 Colors

Colors may be specified as:

- Named colors: `"red"`, `"blue"`, `"black"`, etc.
- Hex: `"#ff0000"`, `"#f00"`
- RGB: `"rgb(255, 0, 0)"`
- RGBA: `"rgba(255, 0, 0, 0.5)"`

## 5. Paginated Presentation

### 5.1 Structure

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

### 5.2 Page Sizes

| Name | Dimensions | Use |
|------|------------|-----|
| `letter` | 8.5 × 11 in | US standard |
| `legal` | 8.5 × 14 in | US legal |
| `a4` | 210 × 297 mm | International standard |
| `a5` | 148 × 210 mm | Half A4 |
| Custom | `{ "width": "8in", "height": "10in" }` | Any size |

### 5.3 Page Elements

Each page contains positioned elements that reference content blocks:

```json
{
  "number": 1,
  "elements": [
    {
      "blockRef": "block-123",
      "position": {
        "x": "1in",
        "y": "1in",
        "width": "6.5in",
        "height": "auto"
      },
      "style": "heading1"
    },
    {
      "blockRef": "block-456",
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
| `blockRef` | string | Yes | Reference to content block ID |
| `position` | object | Yes | Position and size |
| `style` | string | No | Named style to apply |
| `overflow` | string | No | "visible", "hidden", "flow" |

### 5.4 Flow Elements

For automatic text flow across pages:

```json
{
  "type": "flow",
  "blockRefs": ["block-1", "block-2", "block-3"],
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

## 6. Continuous Presentation

### 6.1 Structure

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

### 6.2 Sections

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

## 7. Responsive Presentation

### 7.1 Structure

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

### 7.2 Breakpoints

```json
{
  "breakpoints": [
    { "name": "mobile", "maxWidth": "599px" },
    { "name": "tablet", "minWidth": "600px", "maxWidth": "1023px" },
    { "name": "desktop", "minWidth": "1024px" }
  ]
}
```

### 7.3 Responsive Styles

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

## 8. Style Definitions

### 8.1 Named Styles

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

### 8.2 Default Styles

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

### 8.3 Style Inheritance

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

## 9. Block Type Styling

### 9.1 Automatic Style Mapping

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

### 9.2 Custom Block Styles

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

## 10. Presentation Caching

### 10.1 Cached vs. Computed

Presentation layers MAY be:

1. **Stored (cached)**: Pre-computed and saved in the document
2. **Computed**: Generated on-demand from content and styles

Recommendation:
- Store paginated presentation for print fidelity
- Compute continuous/responsive for flexibility

### 10.2 Cache Invalidation

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

## 11. Fallback Behavior

### 11.1 Missing Presentation

If no presentation layer is present:

1. Apply default styles to all blocks
2. Render in continuous vertical scroll
3. Use system fonts and sensible defaults

### 11.2 Unsupported Elements

For content blocks without styling rules:

1. Apply generic block styling
2. Log warning for implementers
3. Render content in fallback style

## 12. Print Considerations

### 12.1 Page Breaks

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

### 12.2 Headers and Footers

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

## 13. Accessibility

### 13.1 Requirements

Presentation layers MUST NOT:

- Hide content visually that should be accessible
- Use color alone to convey meaning
- Specify text smaller than reasonable minimum (12px recommended)

### 13.2 Contrast

For text colors, ensure sufficient contrast ratio:

- Normal text: 4.5:1 minimum
- Large text (18pt+ or 14pt+ bold): 3:1 minimum

## 14. Examples

### 14.1 Minimal Continuous Presentation

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

### 14.2 Print-Ready Paginated Presentation

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
