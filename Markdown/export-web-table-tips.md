# How to Export a Web Table

## Option 1 — Copy/Paste Directly (Quickest)
1. Click the top-left cell of the table on the webpage
2. Ctrl+Shift+End to select to the end, or drag-select the whole table
3. Ctrl+C then paste into Excel — it usually lands in columns automatically

## Option 2 — Browser Built-in (via Inspector)
1. Right-click the table on the webpage
2. Select Inspect
3. Find the <table> tag in the HTML panel
4. Right-click it -> Copy -> Copy outerHTML
5. Paste into an HTML-to-Excel converter

## Option 3 — Browser Console (Quick Script)
1. Press F12 to open Developer Tools
2. Click the Console tab
3. Paste the following and press Enter:

    copy([...document.querySelectorAll('table tr')].map(r=>[...r.querySelectorAll('th,td')].map(c=>c.innerText).join('\t')).join('\n'))

4. Open Excel and press Ctrl+V — values will split into columns automatically

## Option 4 — Chrome Extensions
- Table Capture
- Copy as Markdown Table

Both are free, one-click export to clipboard or CSV.

## Notes
- Option 3 (console script) works best for tables that are hard to select manually
- If the page requires login or is dynamically loaded, Option 3 or an extension will be more reliable than copy/paste
- If the table spans multiple pages, you may need to export each page separately
