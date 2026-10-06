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

// ---------------- content ----------------
const blocking = [
  [V, 'v2err#0\nA required field is blank (freight code, ship-to, credit status, customer, carrier or packing basis), or the order has no items.',
    'Any of those fields is blank, or there are no item lines.',
    'Fill in the missing field (freight code, carrier and packing basis are on the Order / Ship Info tab) or add items, then save again.'],
  [V, 'v2err#1a\nFreight was added by hand, but the freight code will charge it again at invoicing.',
    'Customer credit status is COD, CASH or PREPAY; the freight code adds freight automatically; the carrier is not Will Call; and a freight line is already on the order.',
    'Change the Freight Code to Prepaid.'],
  [V, 'v2err#1c\nThis customer\'s freight must be added by hand and the freight code changed.',
    'Same as 1a, but no freight line is on the order yet.',
    'Change the Freight Code to Prepaid and add a Freight Charge item (the message suggests the price).'],
  [V, 'v2err#2a\nFreight would be charged twice.',
    'The freight code adds freight automatically, a Freight Charge item was also added by hand, and the packing basis is Order Complete.',
    'Remove the Freight Charge line, or change the Freight Code to Prepaid.'],
  [V, 'v2err#2b\nAn open Freight Charge item is already on the order, so freight would be charged too many times.',
    'The freight code adds freight automatically, a Freight Charge line is still open, and the packing basis is not Order Complete.',
    'Remove the open Freight Charge line, or change the Freight Code to Prepaid.'],
  [V, 'v2err#3a\nThe Prepaid freight code is set but the Freight Charge item is missing.',
    'Freight code is Prepaid, there is no freight line, the carrier is not Will Call, and the packing basis is Order Complete.',
    'Add a Freight Charge item (the message suggests the price).'],
  [V, 'v2err#3b\nPrepaid freight code, there are open items, but no open Freight Charge item.',
    'Freight code is Prepaid, items are still open, there is no open freight line, the carrier is not Will Call, and the packing basis is not Order Complete.',
    'Add a Freight Charge item (the message suggests the price).'],
  [V, 'v2err#4a\nThe carrier is not marked as a Will Call carrier.',
    'Freight code is WILL CALL but the carrier is not a Will Call carrier.',
    'Change the carrier to a Will Call one, or change the Freight Code (for example Out Freight or No Freight).'],
  [V, 'v2err#4c\nThe carrier is marked as a Will Call carrier.',
    'The freight code is not WILL CALL, THIRD or IN FREIGHT, but the carrier is a Will Call carrier.',
    'Change the carrier to a non-Will-Call one, or change the Freight Code to WILL CALL.'],
  [V, 'v2err#6a\nThe order must go on Will Advise because a freight quote is needed.',
    'Customer is COD, CASH or PREPAY; freight on the order is $0; the carrier is not Will Call; the freight code is not NO FREIGHT, IN FREIGHT, FREE DAYS or THIRD; and the Required Date is not already a Will Advise date.',
    'Change the Required Date to 12/31/49.'],
  [V, 'v2err#6b\nThe order is on Will Advise but a freight quote was recently added, so it may be ready to pick.',
    'Required Date is a Will Advise date, freight is now more than $0, the "Freight Quote Required" note is on the order, the carrier is not Will Call, and the freight code is not one of the exempt codes above.',
    'Update the Required Date, or uncheck "Mandatory" on the Freight Quote Required note.'],
  [V, 'v2err#7\nThe order has over $15,000 of product but no Signature Required header note.',
    'Order total is $15,000 or more, there is no "Signature Required" note, and the order type is not blank and not "CUO Entry".',
    'On the Order Notes tab, click Add Note, choose the "Signature Required: Large Order" notepad class, and add the note to Print Invoices and Print Order Acknowledgements.'],
  [V, 'Surcharge message\nThe wording comes from the Atlas surcharge component, not from this rule.',
    'Atlas\'s freight-surcharge check fails.',
    'Follow the Atlas message. It is shown above any v2err message.'],
];

const ruleError = [
  [V, '"The Order Validator business rule hit an error and got no data back from SQL. This error has been logged. If you continue to get it, please contact ITSupport@allsurfaces.com."',
    'The rule asks the database to check the order and gets nothing back.',
    'No — the order still saves. Contact support if it keeps happening.'],
  [V, '"[number] - The [rule name] business rule hit this error while [step]: [error text]. This error has been logged. If you continue to get it, please contact ITSupport@allsurfaces.com."',
    'The rule hits any other unexpected problem while checking the order.',
    'No — the order still saves. Contact support if it keeps happening.'],
];

const warnings = [
  [S, '"This customer has overdue invoices."',
    'An approved, unpaid, undisputed invoice with a balance is more than 20 days past its due date.', 'No \u2014 warning only'],
  [S, '"No contacts found."', 'The customer has no active contacts.', 'No \u2014 warning only'],
  [S, '"Multiple contracts found. Please select a Contract No."',
    'More than one active contract matches the customer, ship-to and default location.', 'No \u2014 warning only'],
  [FS + '\n' + FC + '\n(Front Counter)', '"This customer has overdue invoices. This order will be placed on credit hold."',
    'Same overdue test as above.', 'No \u2014 warning only'],
  [FS + '\n' + FC + '\n(Front Counter)', '"No contacts exist for this customer."', 'The customer has no active contacts.', 'No \u2014 warning only'],
  [FS + '\n(Front Counter)', '"Multiple contracts found for Customer ID and Ship To ID combination. Please, select a Contract No."',
    'More than one active contract matches the customer and ship-to (no location check).', 'No \u2014 warning only'],
];

const quiet = [
  [SUP, 'Hides certain built-in P21 Order Entry popups so the warnings in 3c can show our own wording instead. Which popups are hidden is controlled by a list that can be changed without redeploying the rule.', 'Popups the user would otherwise see are hidden.', 'n/a'],
  [WF, 'Runs after the order is saved and adds a "Freight Quote Required" note to the order when a freight quote is needed. The note is signed "- Karen B," (a departed employee).', 'Users see the note on the Order Notes tab, not a popup.', 'n/a'],
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
  new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: 'Order Entry Messages', font: 'Calibri', size: 40, bold: true, color: NAVY })] }),
  new Paragraph({ spacing: { after: 200 }, children: [new TextRun({
    text: 'Business Rules: ' + [V, S, FS, FC, SUP, WF].join(', ') + '   |   Platform: Prophet21 (P21)   |   Last reviewed: 2026-10-06',
    font: 'Calibri', size: 20, color: GREY })] }),

  h1('1. What It Does'),
  para('This document lists every message a user can see from the Order Entry business rules, which rule produces it, and what has to be true for it to appear. There are two kinds of message:'),
  bullet('Blocking \u2014 the order cannot be saved until the user fixes the problem and tries again.'),
  bullet('Warning \u2014 the user is told something (for example, overdue invoices) but can carry on.'),

  h1('2. When It Runs'),
  bullet('When an order is saved in Order Entry (the order validator, kb_Order_Validator_v2).'),
  bullet('When the ship-to or customer is entered or changed in Order Entry or Front Counter (the warning rules).'),

  h1('3. Why It Exists'),
  para('The validator stops orders with missing or conflicting freight, carrier, Will Call, Required Date or signature information from reaching the warehouse and invoicing. The warning rules put back popups that P21 would otherwise show on its own, with wording and tests we control.'),

  h2('3a. Blocking messages when an order is saved'),
  para('The checks run in this order and the first one that applies is the only one shown. The rule skips orders created before 7/23/2018, and RMA, quote and cancelled orders.'),
  table(['Rule', 'Message', 'When it appears', 'What the user does'], blocking),
  gap(),

  h2('3b. If the rule itself has a problem'),
  table(['Rule', 'Message', 'When it appears', 'Blocks the save?'], ruleError),
  gap(),

  h2('3c. Warnings when the ship-to or customer is entered'),
  table(['Rule', 'Message', 'When it appears', 'Blocks the save?'], warnings),
  gap(),

  h2('3d. Rules that change what the user sees without showing a message'),
  table(['Rule', 'What it does', 'What the user notices', 'Blocks the save?'], quiet),
  gap(),

  ...(CHAD ? [] : [
  h2('Flags'),
  flag('An order whose carrier is not recognized skips the Will Call and freight checks (1, 3, 4 and 6) and saves without them. This is carried over from the old validator and has not been fixed.'),
  flag('The validator and the Freight Quote Required note rule use different credit statuses for the same customer. They disagree for 577 customers, so the 6b message can never appear for them. The business owner of the freight-quote process needs to say which status is correct.'),
  flag('Freight Quote Required notes are signed "- Karen B," even though that person has left the company.'),
  flag('The two live freight rules (kb_Order_Validator_v2 and kb_Order_Workflow_v2) are KB-built objects. KB is a departed employee and retiring kb_ objects is a 2026 goal. A rewrite (asi_Order_Validator) is built and tested but is not live yet; its message wording is identical to what is listed here. Details are in the appendix.'),
  para([run('To confirm: ', { bold: true }), run('the exact wording of the Atlas surcharge message, which popup numbers the suppression list currently hides, and the roles the validator is restricted to.')]),

  ]),

  h1('4. Roles / Users Affected'),
  para('Not everyone \u2014 each rule is restricted to specific roles. Note that "ALL" is the name of a role that users are assigned to; it does not mean every user.'),
  bullet(S + ' and ' + SUP + ': ALL, Customer Service, Customer Service Manager, Outside Sales, Sales Manager.'),
  bullet(FS + ': ALL, Customer Service, Customer Service Manager, Outside Sales, Sales Manager.'),
  bullet(FC + ': ALL, Claims, Customer Service, Outside Sales, Sales Manager.'),
  bullet(V + ' and ' + WF + ': restricted to specific roles (including ALL); the full list is still being confirmed.'),

  h1('5. Owner / Status'),
  new Table({
    width: { size: 9360, type: WidthType.DXA }, columnWidths: [2200, 7160],
    rows: [
      kv('Owner', 'Mark Goldyn'),
      kv('Status', 'Active in Production \u2014 runs on the Order Entry and Front Counter screens'),
    ],
  }),

  ...(CHAD ? [] : [
  h1('6. Appendix \u2014 Technical Detail'),
  para([run('For IT reference only.', { italics: true, color: GREY })]),
  bullet('Validator: kb_Order_Validator_v2 (C# business rule). It builds order-line, payment-line and note tables, calls the SQL function dbo.kb_fnt_br_order_validator_v2, and shows the function\'s result_message; it then calls Surcharge.Validate for the Atlas check. Source: C:\Claude\CSharp\kb_Order_Validator_v2.cs.'),
  bullet('The check logic was re-documented from its C# port (OrderValidationEngine.cs / asi_Order_Validator_t2.cs), which reproduces the SQL function bug-for-bug and matched the old function on all 23 test cases. The port is NOT live in Production. Nine checks run as an ordered chain, first match wins. Signature threshold = 15000. Exempt freight codes for quote checks: 5, 7, 10, 12. Freight codes allowing a Will Call carrier: 8, 12, 7. Prepaid = 6, Will Call = 8.'),
  bullet('Will Advise dates (Required Date): 12/31/2049 and 2/22/2022 (retired row that still matches \u2014 preserved bug). 3/3/2033 = Ship with Other Goods, 3/23/2033 = Reserve. Freight items: FREIGHT CHARGE, UPS CHARGE, SPEEDEE CHARGE.'),
  bullet('Rule-error behavior: both 3b messages leave the save allowed. The Atlas message is placed ahead of the v2err message.'),
  bullet('Warning rules: ' + S + ' (fires on ship_to_id change; also sets sales_loc_id from the ship-to default branch) and ' + FS + ' / ' + FC + ' (Front Counter). Overdue test: p21_view_invoice_hdr, approved, not paid in full, not consolidated, not record_type 3023, DATEDIFF(dd, net_due_date, now) > 20, not disputed, open balance > 0. Contacts: oe_contacts_customer / contacts. Contracts: job_price_hdr / job_price_customer_shipto / job_price_line, row_status_flag 704, active dates, count > 1. Source copy in repo is _t9_oe_order_sales_loc_id_up.cs (same wording as v8).'),
  bullet('Suppression: ' + SUP + ' is driven by suppress_messages_p21_ud via usp_suppress_messages_p21_ud (SUPPRESS / ALLOW / LOG actions, logging to message_log_p21_ud). Version comments disagree on whether message 451 or 688 is "overdue" vs "no contacts" \u2014 check the table before documenting message numbers.'),
  flag('kb_ dependencies: kb_Order_Validator_v2 calls dbo.kb_fnt_br_order_validator_v2 and the kb_ lookup objects behind it (e.g. dbo.kb_table_required_date_statuses, dbo.kb_fn_number_shorten, kb_TableType* table types). kb_Order_Workflow_v2 calls kb_proc_br_oe_hdr_note and reads kb_view_customer logic. All are retirement candidates once the asi_ replacements go live.'),
  flag('Credit-status mismatch: kb_Order_Workflow_v2 uses the corporate-rollup credit status (the corporate parent\'s credit status when the account is a child or has no credit limit); the validator reads the plain customer credit status. 577 customers differ.'),
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
