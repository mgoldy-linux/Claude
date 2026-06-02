'use strict';
// build-brr-docx.js
// Called by Run-BRR-Verification.ps1
// Usage: node build-brr-docx.js <inputJson> <outputDocx>

const fs   = require('fs');
const path = require('path');

// Resolve 'docx' from the local node_modules next to this script,
// falling back to the global install. This handles both npm install -g
// and local npm install in the script folder.
const docxPath = (() => {
  const local = path.join(__dirname, 'node_modules', 'docx');
  try { require.resolve(local); return local; } catch (_) {}
  return 'docx'; // fall back to global / PATH resolution
})();

const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, PageOrientation, BorderStyle,
  WidthType, ShadingType, VerticalAlign, PageNumber, HeadingLevel,
  TabStopType, TabStopPosition
} = require(docxPath);

// ── Args ────────────────────────────────────────────────────────────────────
const [,, inputJson, outputDocx] = process.argv;
if (!inputJson || !outputDocx) {
  console.error('Usage: node build-brr-docx.js <input.json> <output.docx>');
  process.exit(1);
}
const payload = JSON.parse(fs.readFileSync(inputJson, 'utf8'));
// payload = { generatedAt, server, sections: [ { title, db, rowCount, columns, rows } ] }

// ── Colour palette ───────────────────────────────────────────────────────────
const BRAND_DARK  = '1E3A5F';
const BRAND_MID   = '0078D4';
const BRAND_LIGHT = 'D0E4F5';
const HEADER_BG   = '1E3A5F';
const ROW_ALT     = 'F0F5FB';
const OK_COLOR    = '107C10';
const FAIL_COLOR  = 'C50F1F';
const MUTED       = '6B7280';

// ── Helpers ──────────────────────────────────────────────────────────────────
const cellBorder = { style: BorderStyle.SINGLE, size: 1, color: 'C8D8E8' };
const borders    = { top: cellBorder, bottom: cellBorder, left: cellBorder, right: cellBorder };

function safe(val) {
  if (val === null || val === undefined) return '';
  return String(val);
}

function headerCell(text, widthDxa, noWrap = false) {
  return new TableCell({
    borders,
    width:   { size: widthDxa, type: WidthType.DXA },
    shading: { fill: HEADER_BG, type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    verticalAlign: VerticalAlign.CENTER,
    ...(noWrap ? { noWrap: true } : {}),
    children: [new Paragraph({
      children: [new TextRun({ text, bold: true, color: 'FFFFFF', size: 18, font: 'Arial' })]
    })]
  });
}

function dataCell(text, widthDxa, opts = {}) {
  const { isAlt, color, noWrap } = opts;
  return new TableCell({
    borders,
    width:   { size: widthDxa, type: WidthType.DXA },
    shading: { fill: isAlt ? ROW_ALT : 'FFFFFF', type: ShadingType.CLEAR },
    margins: { top: 60, bottom: 60, left: 120, right: 120 },
    verticalAlign: VerticalAlign.CENTER,
    ...(noWrap ? { noWrap: true } : {}),
    children: [new Paragraph({
      children: [new TextRun({
        text,
        size:  18,
        font:  'Arial',
        color: color || '1A1A1A',
        bold:  !!color
      })]
    })]
  });
}

function buildSectionTable(section) {
  const cols   = section.columns;   // string[]
  const rows   = section.rows;      // string[][]
  const noWrap = !!section.noWrap;
  const count  = cols.length || 1;

  // Landscape content width = 15840 - 1440 - 1440 = 12960 DXA
  const totalW    = 12960;
  const colW      = Math.floor(totalW / count);
  // give last column the remainder
  const colWidths = cols.map((_, i) => i === cols.length - 1 ? totalW - colW * (count - 1) : colW);

  const tableRows = [];

  // Header row – noWrap on header cells too so column names don't wrap
  tableRows.push(new TableRow({
    tableHeader: true,
    children: cols.map((c, i) => headerCell(c, colWidths[i], noWrap))
  }));

  // Data rows
  if (!rows || rows.length === 0) {
    tableRows.push(new TableRow({
      children: [new TableCell({
        borders,
        columnSpan: count,
        width:   { size: totalW, type: WidthType.DXA },
        shading: { fill: 'FFFFFF', type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({
          children: [new TextRun({ text: 'No rows returned.', italics: true, color: MUTED, size: 18, font: 'Arial' })]
        })]
      })]
    }));
  } else {
    rows.forEach((row, rIdx) => {
      const isAlt = rIdx % 2 === 1;
      tableRows.push(new TableRow({
        children: row.map((val, cIdx) => {
          const text = safe(val);
          let color;
          if (cols[cIdx] === 'RunStatus') {
            if (text === 'Succeeded') color = OK_COLOR;
            else if (text === 'Failed')    color = FAIL_COLOR;
          }
          return dataCell(text, colWidths[cIdx], { isAlt, color, noWrap });
        })
      }));
    });
  }

  return new Table({
    width: { size: totalW, type: WidthType.DXA },
    columnWidths: colWidths,
    rows: tableRows
  });
}

// ── Document ─────────────────────────────────────────────────────────────────
const children = [];

// Title
children.push(new Paragraph({
  children: [new TextRun({
    text: 'BRR Refresh Verification Report',
    bold: true, size: 36, font: 'Arial', color: BRAND_DARK
  })],
  spacing: { after: 80 }
}));

// Subtitle line
children.push(new Paragraph({
  children: [
    new TextRun({ text: 'Server: ', bold: true, size: 20, font: 'Arial', color: MUTED }),
    new TextRun({ text: payload.server, size: 20, font: 'Arial', color: MUTED }),
    new TextRun({ text: '    Generated: ', bold: true, size: 20, font: 'Arial', color: MUTED }),
    new TextRun({ text: payload.generatedAt, size: 20, font: 'Arial', color: MUTED }),
  ],
  spacing: { after: 0 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BRAND_MID, space: 1 } }
}));

children.push(new Paragraph({ children: [], spacing: { after: 200 } }));

// Sections
payload.sections.forEach(section => {
  // Section heading
  children.push(new Paragraph({
    children: [
      new TextRun({ text: section.title, bold: true, size: 24, font: 'Arial', color: BRAND_DARK }),
      new TextRun({ text: `  (${section.rowCount} row${section.rowCount !== 1 ? 's' : ''})`, size: 20, font: 'Arial', color: MUTED }),
    ],
    spacing: { before: 240, after: 100 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 3, color: BRAND_LIGHT, space: 1 } }
  }));

  // Table
  children.push(buildSectionTable(section));
  children.push(new Paragraph({ children: [], spacing: { after: 160 } }));
});

// ── Build & write ─────────────────────────────────────────────────────────────
const doc = new Document({
  styles: {
    default: { document: { run: { font: 'Arial', size: 20 } } }
  },
  sections: [{
    properties: {
      page: {
        size: {
          width:       12240,
          height:      15840,
          orientation: PageOrientation.LANDSCAPE
        },
        margin: { top: 900, right: 900, bottom: 900, left: 900 }
      }
    },
    headers: {
      default: new Header({
        children: [new Paragraph({
          children: [
            new TextRun({ text: 'BRR Refresh Verification', bold: true, size: 18, font: 'Arial', color: BRAND_DARK }),
            new TextRun({ text: '\t\t', size: 18 }),
            new TextRun({ text: payload.generatedAt, size: 18, font: 'Arial', color: MUTED }),
          ],
          tabStops: [
            { type: TabStopType.RIGHT, position: 12960 }
          ],
          border: { bottom: { style: BorderStyle.SINGLE, size: 3, color: BRAND_MID, space: 1 } }
        })]
      })
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({
          children: [
            new TextRun({ text: payload.server, size: 16, font: 'Arial', color: MUTED }),
            new TextRun({ text: '\t\tPage ', size: 16, font: 'Arial', color: MUTED }),
            new TextRun({ children: [PageNumber.CURRENT], size: 16, font: 'Arial', color: MUTED }),
            new TextRun({ text: ' of ', size: 16, font: 'Arial', color: MUTED }),
            new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 16, font: 'Arial', color: MUTED }),
          ],
          tabStops: [{ type: TabStopType.RIGHT, position: 12960 }]
        })]
      })
    },
    children
  }]
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync(outputDocx, buf);
  console.log('OK:' + outputDocx);
});
