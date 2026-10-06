# Order Entry Messages docs — generator

Builds the two Summary docx (Order Entry Messages, ribbon_oe_default_branch). Edit the content arrays at the top of each script, rebuild, copy out.

```powershell
$env:NODE_PATH = "$env:APPDATA\npm\node_modules"      # docx is installed globally here; no download needed
node make_summary.js <out.docx>          # Mark's full version (Flags + Appendix)
node make_summary.js <out.docx> chad     # Chad's version (no Flags / To confirm / Appendix)
node make_ribbon.js  <out.docx> [chad]
```

Destinations (see memory `project_order_entry_messages_summary_docs`):
- `...\Platforms\P21\_Veirfied Business Rules\Order-Entry-Messages\` and `\ribbon_oe_default_branch\` — `Summary-*.docx` = Chad version, `*-Full-Technical.docx` = Mark's.
- Chad's hand-copied file: `...\Platforms\Order Entry Improvement Project\Summary-Order-Entry-Messages.docx` — re-copy after every rebuild.

No LibreOffice/pdftoppm/pandoc on the work laptop, so output can only be validated (`validate.py` in the docx skill), not rendered. Open in Word to eyeball.
