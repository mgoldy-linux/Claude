const fs = require('fs');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType,
  ShadingType, BorderStyle, AlignmentType, LevelFormat, HeadingLevel,
} = require('docx');

const NAVY = '1F3B57', GREY = '606060', ORANGE = 'B05000';
const OUT = process.argv[2];
const CHAD = process.argv[3] === 'chad';

const V = 'kb_Order_Validator_v2';
const S = 'asi_oe_order_sales_loc_id_up';
const SUP = 'asi_oe_suppress_oe_msgs';
const WF = 'kb_Order_Workflow_v2';
const FS = 'asi_fc_restore_msg_ship_to_id';
const FC = 'asi_fc_restore_msg_cust_id';

const run = (t, o = {}) => new TextRun({ text: t, font: 'Calibri', size: 22, ...o });
const para = (t, o = {}) => new Paragraph({ spacing: { after: 120 }, children: Array.isArray(t) ? t : [run(t)], ...o });
const h1 = (t) => new Paragraph({
  heading: HeadingLevel.HEADING_1, spacing: { before: 280, after: 120 },
  children: [new TextRun({ text: t, font: 'Calibri', size: 28, bold: true, color: NAVY })],
});
const h2 = (t) => new Paragraph({
  heading: HeadingLevel.HEADING_2, spacing: { before: 200, after: 100 },
  children: [new TextRun({ text: t, font: 'Calibri', size: 24, bold: true, color: NAVY })],
});
const flag = (t) => para([run('\u26A0 Flag \u2014 ', { bold: true, color: ORANGE }), run(t, { color: ORANGE })]);
const bullet = (t) => new Paragraph({ numbering: { reference: 'b', level: 0 }, spacing: { after: 60 }, children: [run(t)] });

const border = { style: BorderStyle.SINGLE, size: 4, color: 'BFBFBF' };
const borders = { top: border, bottom: border, left: border, right: border };
const W = [1900, 2500, 3000, 1960];
const cell = (t, i, head, shade) => new TableCell({
  width: { size: W[i], type: WidthType.DXA }, borders,
  margins: { top: 60, bottom: 60, left: 90, right: 90 },
  shading: head ? { type: ShadingType.CLEAR, fill: NAVY, color: 'auto' }
                : shade ? { type: ShadingType.CLEAR, fill: 'F2F5F8', color: 'auto' } : undefined,
  children: String(t).split('\n').map((line) => new Paragraph({
    spacing: { after: 40 },
    children: [new TextRun({ text: line, font: 'Calibri', size: 18, bold: !!head, color: head ? 'FFFFFF' : undefined })],
  })),
});
const table = (headers, rows) => new Table({
  width: { size: W.reduce((a, b) => a + b, 0), type: WidthType.DXA },
  columnWidths: W,
  rows: [
    new TableRow({ tableHeader: true, children: headers.map((h, i) => cell(h, i, true)) }),
    ...rows.map((r, n) => new TableRow({ cantSplit: true, children: r.map((c, i) => cell(c, i, false, n % 2 === 1)) })),
  ],
});
const gap = () => new Paragraph({ spacing: { after: 80 }, children: [] });

const RB = 'ribbon_oe_default_branch';
const msgs = [
  [RB, '"Ship to ID is required."', 'No ship-to ID is available when the ribbon loads.', 'Ribbon shows no branch'],
  [RB, '"No default branch found for ship to ID [ship-to]."', 'The ship-to has no default branch on file.', 'Ribbon shows no branch'],
];
const kv = (label, value) => new TableRow({
  children: [
    new TableCell({ width: { size: 2200, type: WidthType.DXA }, borders, margins: { top: 60, bottom: 60, left: 90, right: 90 },
      shading: { type: ShadingType.CLEAR, fill: 'F2F5F8', color: 'auto' },
      children: [new Paragraph({ children: [run(label, { bold: true })] })] }),
    new TableCell({ width: { size: 7160, type: WidthType.DXA }, borders, margins: { top: 60, bottom: 60, left: 90, right: 90 },
      children: [new Paragraph({ children: [run(value)] })] }),
  ],
});


const children = [
  new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: 'Order Entry Ribbon \u2014 Default Branch', font: 'Calibri', size: 40, bold: true, color: NAVY })] }),
  new Paragraph({ spacing: { after: 200 }, children: [new TextRun({
    text: 'Ribbon Rule: ' + RB + '   |   Platform: Prophet21 (P21)   |   Last reviewed: 2026-10-06', font: 'Calibri', size: 20, color: GREY })] }),

  h1('1. What It Does'),
  para('Shows the ship-to\u2019s default branch on the Order Entry ribbon (in larger type) so the user can see at a glance which branch the order will normally come from. If it cannot find a branch, it shows a short message instead.'),

  h1('2. When It Runs'),
  para('When an order is opened or loaded in Order Entry, using the ship-to on the order. It does not run when the order is saved, so these messages can appear a few seconds before any save-time message and are not save errors.'),

  h1('3. Why It Exists'),
  para('Gives order takers the default branch without opening the ship-to record, which helps them check that the Sales Location is right.'),
  h2('Messages'),
  table(['Rule', 'Message', 'When it appears', 'Result'], msgs),
  gap(),
  ...(CHAD ? [] : [
  flag('The "Ship to ID is required." message has been mistaken for an order-save error. It comes from this ribbon rule, not from the order validator, and it does not block anything.'),
  para([run('To confirm: ', { bold: true }), run('which roles see this ribbon.')]),

  ]),

  h1('4. Roles / Users Affected'),
  para('Not everyone \u2014 which roles is still being confirmed.'),

  h1('5. Owner / Status'),
  new Table({
    width: { size: 9360, type: WidthType.DXA }, columnWidths: [2200, 7160],
    rows: [
      kv('Owner', 'Mark Goldyn'),
      kv('Status', 'Active in Production \u2014 shows on the Order Entry ribbon'),
    ],
  }),

  ...(CHAD ? [] : [
  h1('6. Appendix \u2014 Technical Detail'),
  para([run('For IT reference only.', { italics: true, color: GREY })]),
  bullet('Object: ribbon_oe_default_branch (C# ribbon business rule). In source the class and namespace are named ribbon_oe_default_branch_T2; source file C:\Claude\CSharp\ribbon_oe_default_branch.cs.'),
  bullet('Reads the ship_to_id field, then SELECT default_branch FROM ship_to WITH (NOLOCK) WHERE ship_to_id = @ship2id. On success it writes the branch to business_rule_result and sets business_rule_result_font_size to 14.'),
  bullet('On failure it returns Success = false with one of the two messages above (any exception returns the exception text).'),
  bullet('Ribbon rules write Invoke/Return rows to business_rule_log on order load, which is why a Fail from this rule shows up just before the save-time validator in the log.'),
  para([run('No kb_, js_ or ds_ dependency. Performance: a single indexed-key lookup on ship_to; nothing to improve.', { color: GREY })]),
  ]),
];

const doc = new Document({
  styles: { default: { document: { run: { font: 'Calibri', size: 22 } } } },
  numbering: { config: [{ reference: 'b', levels: [{ level: 0, format: LevelFormat.BULLET, text: '\u2022', alignment: AlignmentType.LEFT,
    style: { paragraph: { indent: { left: 540, hanging: 270 } } } }] }] },
  sections: [{
    properties: { page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    children,
  }],
});

Packer.toBuffer(doc).then((buf) => { fs.writeFileSync(OUT, buf); console.log('wrote', OUT); });
