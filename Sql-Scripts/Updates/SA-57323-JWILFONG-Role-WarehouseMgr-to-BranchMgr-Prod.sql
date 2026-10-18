-- SA 57323 - John Wilfong (JWILFONG): change P21 role Warehouse Manager (role_uid 20) -> Branch Manager (role_uid 2).
-- Requester confirmed the reduced access is intended. Prod 2026-10-16: Branch Manager menu access is a strict subset of
-- Warehouse Manager (496 screens lost, 0 gained; see Data-Out\Excel\SA-57323-BranchMgr-vs-WarehouseMgr-Menu-Access-Prod-*.xlsx).
-- JWILFONG has no user-level menu overrides and no direct portal_assignment rows, so the role is the only thing that changes.
-- Only role_uid is touched (Update-1-User.sql template also rewrites ~25 user-tab flags; those are per user and are left alone here).
-- Rollback value if needed: role_uid = 20.
USE P21;

SELECT u.id, u.name, u.delete_flag, u.default_branch, u.role_uid, r.role AS role_before
FROM users u LEFT JOIN roles r ON r.role_uid = u.role_uid
WHERE u.id = 'JWILFONG';   -- expect 1 row, role_uid 20 Warehouse Manager

BEGIN TRAN;

UPDATE users
SET role_uid = (SELECT role_uid FROM roles WHERE role = 'Branch Manager')   -- 2
WHERE id = 'JWILFONG' AND role_uid = (SELECT role_uid FROM roles WHERE role = 'Warehouse Manager');   -- 20

IF @@ROWCOUNT <> 1
BEGIN
    ROLLBACK;
    RAISERROR('Expected exactly 1 row (JWILFONG still Warehouse Manager) - rolled back, nothing changed.', 16, 1);
END
ELSE
BEGIN
    COMMIT;
    PRINT 'Committed: JWILFONG is now Branch Manager.';
END

SELECT u.id, u.name, u.role_uid, r.role AS role_after
FROM users u LEFT JOIN roles r ON r.role_uid = u.role_uid
WHERE u.id = 'JWILFONG';   -- expect role_uid 2 Branch Manager
