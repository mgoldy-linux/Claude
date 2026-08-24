--Code for [dbo].[p21_dynachange_info_web]
			

--CREATE PROCEDURE p21_dynachange_info_web

@object		VARCHAR(128)
,@user_id	VARCHAR(30) 
AS  
BEGIN  

DECLARE @role_uid			INTEGER
DECLARE @custom_objects_uid	INTEGER
DECLARE @design_uid			INTEGER
DECLARE @type				INTEGER
DECLARE @assignment_uid		INTEGER
DECLARE @leftside			VARCHAR(255)
DECLARE @rightside			VARCHAR(255)
DECLARE @base_leftside		VARCHAR(255)
DECLARE @base_rightside		VARCHAR(255)
DECLARE @window				VARCHAR(255)
DECLARE @tab				VARCHAR(255)
DECLARE @tabpage			VARCHAR(255)
DECLARE @dwname				VARCHAR(255)
DECLARE @dwobject			VARCHAR(255)
DECLARE @newobject			VARCHAR(255)
DECLARE @originalobject 	VARCHAR(255)


-- The object FROM web will be formatted for datawindow as below
-- windowname.tabname.tabpagename.datawindowname.dataobjectname with custom config.

-- The object FROM web will be formatted for tab as below
-- windowname.tabname


DECLARE @versioninfo TABLE 
(
	version		VARCHAR(255)
	,role		VARCHAR(255)
	,id			VARCHAR(255)
)

SET		@originalobject = @object

IF PATINDEX('%.%', @object) > 0
BEGIN
	SET		@leftside = LEFT(@object, PATINDEX('%.%', @object) - 1)
	SET		@window = @leftside
	PRINT	'window'
	PRINT	@window
	PRINT	'reverse'
	PRINT	PATINDEX('%.%', reverse(@object))

	SET		@rightside = right(@object, PATINDEX('%.%', reverse(@object)) - 1)
	
	SET		@dwobject  =@rightside

	PRINT	'dw'
	PRINT	@dwobject
	PRINT	'leftside'
	PRINT	@leftside
	PRINT	'rightside'
	PRINT	@rightside
	SET		@base_leftside = (	SELECT		dynachange.base_class
								FROM		dynachange_config
								INNER JOIN	system_setting configuration_id ON (configuration_id.name = 'configuration_id')
											AND (configuration_id.value = dynachange_config.configuration_id)
								LEFT JOIN	dynachange ON dynachange_config.dynachange_id = dynachange.dynachange_id
											AND dynachange.personalized_class = LEFT(@object, PATINDEX('%.%', @object) - 1)
								WHERE		dynachange.personalized_class = LEFT(@object, PATINDEX('%.%', @object) - 1))

	SET @base_rightside = (	SELECT		dynachange.base_class
							FROM		dynachange_config
							INNER JOIN	system_setting configuration_id ON (configuration_id.name = 'configuration_id')
										AND (configuration_id.value = dynachange_config.configuration_id)
							LEFT JOIN	dynachange ON dynachange_config.dynachange_id = dynachange.dynachange_id
										AND dynachange.personalized_class = @rightside
							WHERE		dynachange.personalized_class = @rightside)
	-- remove the config FROM the object and just get the base object.
	SET		@object = COALESCE(@base_leftside, @leftside) + '.' + COALESCE(@base_rightside, @rightside)

	PRINT	'baseleft'
	PRINT	@base_leftside

	PRINT	'baseright'
	PRINT	@base_rightside

	PRINT	'object'
	PRINT	@object
		
	SET		@newobject = REPLACE(@originalobject, @window, COALESCE(@base_leftside, @leftside))
	PRINT	'newobject'
	PRINT	@newobject
	SET		@newobject = REPLACE(@originalobject, @dwobject, COALESCE(@base_rightside, @rightside))

	PRINT	'newobject'
	PRINT	@newobject

	SELECT	@role_uid = role_uid
	FROM	users
	WHERE	id = @user_id

	PRINT	'role'
	PRINT	@role_uid

	SET		@assignment_uid = (	SELECT	top 1 assignment_uid 
								FROM	design
								JOIN	assignment ON design.design_uid = assignment.design_uid
								WHERE	location = @newobject
										AND ((assignee = @user_id and assignment_type = 0)
											OR (role_uid = @role_uid and assignment_type = 1))
								ORDER BY role_uid ASC)

	SET		@design_uid = (	SELECT	top 1 design.design_uid 
							FROM	design
							JOIN	assignment ON design.design_uid = assignment.design_uid
							WHERE	location = @newobject
									AND ((assignee = @user_id and assignment_type = 0)
										OR (role_uid = @role_uid and assignment_type = 1))
							ORDER BY role_uid ASC)
	
	
	PRINT	'assignment_uid'
	PRINT	@assignment_uid
	
	PRINT	'design_uid'

	PRINT	@design_uid
	
	
	IF @design_uid > 0
	
	BEGIN
	
	SELECT	@type = assignment_type
			FROM	assignment
			WHERE	assignment_uid = @assignment_uid
				
			IF @type = 0
			BEGIN
			-- There is web version for this object. It is a user based design version. All users sharing this design will be listed.
				PRINT 'user design'
				INSERT INTO @versioninfo
				(
				version
				,role 
				,id
				)
				(
				SELECT		design.name		AS [version_id]
							,'User Version' AS [role]
							,assignee		AS [id]
				FROM		assignment 
				JOIN		design ON design.design_uid = assignment.design_uid
				WHERE		design.design_uid = @design_uid 
				)
				
			END
			ELSE
			BEGIN
			-- There is web version for this object. It is role based design version. All roles and the users that belong to those roles sharing this design will be listed.
			PRINT 'role design'
				INSERT INTO @versioninfo
				(
				version
				,role 
				,id
				)
				(
				SELECT		design.name									AS [version_id]
							,COALESCE([role], 'Role Has Been Deleted')	AS [role]
							,id											AS [id]
				FROM		users
				INNER JOIN	assignment assignment_role ON (assignment_role.role_uid = users.role_uid)
				INNER JOIN	design ON design.design_uid = assignment_role.design_uid
				LEFT JOIN	assignment assignment_object ON (assignment_role.design_uid = assignment_object.design_uid)
															AND (users.id = assignment_object.assignee)
															AND (assignment_object.assignment_type = 0)
				LEFT JOIN	roles ON (roles.role_uid = assignment_role.role_uid)
			
				WHERE		design.design_uid = @design_uid 
							AND	assignment_object.design_uid IS NULL
							AND	users.delete_flag = 'N'
				)
				END
					
	END
	ELSE
	BEGIN
	-- There is no web version for this object. It has a desktop design.
	PRINT 'desktop design'
		-- 05/08/20 Added @area='W' argument
		INSERT INTO @versioninfo execute  dbo.p21_dynachange_info   @object = @object, @user_id = @user_id, @area = 'W'
	END
END
		SELECT * FROM @versioninfo  group by Version, role, id order by Version asc , role asc , id asc
END

--$Author: Alejandro.macias $
--$Date: 5/08/20 7:55p $
--$Revision: 2 $
--$Log: /Server/CommerceCenter/Z_Ocelot (20.1)/Stored Procedures/p21_dynachange_info_web.sql $
-- 
-- 2     5/08/20 7:55p Alejandro.macias
-- DEV: UV
-- DBA: ALM 
-- Jira P21CD-19185: Modify p21_dynachange_info_web so that any migrated
-- designs will NOT be displayed in the web. Modify to add @area while
-- calling p21_dynachange_info   
-- b020_001_054061.sql
-- 
-- 1     4/28/20 6:37p Alejandro.macias
-- DEV: UV
-- DBA: ALM 
-- Scopus 1418602: Stored Proc to return information of screen/tab version
-- for user 
-- b020_001_053999.sql

			


--Database Version: 20.2.4162	