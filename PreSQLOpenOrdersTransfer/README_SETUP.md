# Pre-SQL Business Rule: Open Orders Transfer Column
## Setup & Deployment Guide

---

## What This Rule Does

Modifies the `d_dw_portal_open_orders` datawindow query in **Customer Master Inquiry** to calculate the **Items on Transfer** column (`ufc_p21soc_items_on_transfer`) instead of returning NULL.

### Two SQL Modifications:
1. **Adds** `items_on_transfer` aggregation to the `der_unshipped_value` subquery:
   ```sql
   ,SUM(CASE WHEN oe_line.disposition = 'T' THEN 1 ELSE 0 END) items_on_transfer
   ```

2. **Replaces** `NULL ufc_p21soc_items_on_transfer` with:
   ```sql
   ,CASE WHEN der_unshipped_value.items_on_transfer > 0 THEN 'Y' ELSE 'N' END ufc_p21soc_items_on_transfer
   ```

---

## Project Files

| File | Purpose |
|------|---------|
| `OpenOrdersTransferRule.cs` | The business rule class (main logic) |
| `PreSQLOpenOrdersTransfer.csproj` | Visual Studio project file (.NET 4.8) |
| `Properties/AssemblyInfo.cs` | Assembly metadata + AllowPartiallyTrustedCallers |

---

## Step-by-Step Setup

### 1. Prepare Visual Studio

1. Open **Visual Studio 2015+** (2019 or 2022 recommended)
2. Go to **File > Open > Project/Solution**
3. Navigate to the folder containing these files and open `PreSQLOpenOrdersTransfer.csproj`

### 2. Fix the P21.Extensions Reference

The project references `P21.Extensions.dll` — you must point it to your actual copy:

1. In **Solution Explorer**, expand **References**
2. If `P21.Extensions` shows a yellow warning icon, right-click it and select **Remove**
3. Right-click **References > Add Reference > Browse**
4. Navigate to your Prophet 21 installation folder (e.g., `C:\Program Files\Epicor\Prophet 21\`)
5. Select `P21.Extensions.dll` and click **OK**

> **Note:** Use `P21.Extensions.dll`, NOT the older `Activant.P21.Extensions.dll`

### 3. Build the Project

1. Set the build configuration to **Release** (dropdown in toolbar)
2. Press **F6** (or Build > Build Solution)
3. Verify no errors in the Output window
4. The DLL will be at: `bin\Release\PreSQLOpenOrdersTransfer.dll`

### 4. Deploy the DLL

1. **Close all Prophet 21 clients** (desktop and web)
2. Copy `PreSQLOpenOrdersTransfer.dll` to your **DLL Folder**
   - Find this path at: Setup > System Setup > System > System Settings > Files and Folders > DLL Folder
3. Verify the file is accessible from all P21 client machines and Middleware servers

### 5. Link the Rule in Prophet 21

1. Open **Prophet 21** (desktop application)
2. Open **Customer Master Inquiry**
3. Navigate to the **Open Orders** tab
4. Right-click any field on the Open Orders grid
5. Select **DynaChange > DynaChange Rules > Create Business Rule**
6. In the New Business Rule dialog:
   - Find **OpenOrdersTransferRule** in the list and check **Selected**
   - Go to the **Configuration Options** tab
   - Set **Rule Type** to **Pre-SQL**
   - Set **Enabled for Version** to the appropriate option (Both, Desktop, or Web Browser)
7. Click **Save**

### 6. Test

1. Open **Customer Master Inquiry**
2. Retrieve a customer with open orders (e.g., customer 3021289 — Rochester Cash Sales)
3. Go to the **Open Orders** tab
4. Verify the **Items on Transfer** column now shows **Y** or **N** instead of blank/NULL
5. Check orders you know have transfer disposition lines to confirm **Y** appears correctly

---

## Troubleshooting

### Rule doesn't appear in the list
- Verify the DLL is in the correct DLL Folder path
- Ensure `P21.Extensions.dll` was referenced (not the old Activant version)
- Restart Prophet 21 after copying the DLL

### Rule appears but doesn't fire
- Confirm the Rule Type is set to **Pre-SQL**
- Check that the rule is **Active** in the Business Rule Organizer (Application > Rules)
- Verify user has DynaChange Rules permissions in User Maintenance

### SQL errors after rule fires
- Log into P21 as a programmer (Alt-T at login) to enable the `business_rule_log` table
- Check the log for the original SQL and verify the string replacements are correct
- The rule includes a LogString for error logging — check the log file output

### Items on Transfer column still shows NULL
- The rule looks for the exact string `NULL ufc_p21soc_items_on_transfer` in the SQL
- If your P21 version uses different casing or spacing, the replacement may not match
- Check the `business_rule_log` to see the actual SQL being passed to the rule

---

## Important Notes

- **Always test in your Play system first** before deploying to Live
- The rule includes idempotency checks — it won't add `items_on_transfer` twice if it already exists
- If you need to deactivate the rule, use Application > Rules and set Row Status to **Inactive**
- The `AllowPartiallyTrustedCallers` attribute is included in AssemblyInfo.cs for network drive compatibility
