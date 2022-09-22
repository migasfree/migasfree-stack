/*
    ====================================
    TEMPLATE: MIGRATION DATABASE FROM V4
    ====================================
*/

CREATE EXTENSION IF NOT EXISTS dblink;
SELECT dblink_connect('REMOTE', 'host=@OLD_HOST@ port=@OLD_PORT@  dbname=@OLD_DB@ user=@OLD_USER@ password=@OLD_PWD@ ');


-- NORMALIZE V4 DATABASE
\echo 'Normalize V4 database'
\! send_message 'database migration: normalize v4 '
select dblink_exec('REMOTE', 'UPDATE server_computer SET ip_address = NULL WHERE ip_address = '''' ');
select dblink_exec('REMOTE', 'UPDATE server_computer SET ip_address = NULL WHERE ip_address = ''unknown'' ');
select dblink_exec('REMOTE', 'UPDATE server_computer SET forwarded_ip_address = NULL WHERE forwarded_ip_address = '''' ');
select dblink_exec('REMOTE', 'UPDATE server_computer SET forwarded_ip_address = NULL WHERE forwarded_ip_address = ''unknown'' ');


-- TEMPORARILY DISABLE ALL TRIGGERS
SET session_replication_role TO 'replica';


-- APPLICATIONS
\echo 'app_catalog_application'
\! send_message 'database migration: app_catalog_application '
DELETE FROM app_catalog_application;
INSERT INTO app_catalog_application
    SELECT T.*
 FROM dblink('REMOTE', 'select
     id, name, description, created_at, score, icon, level, category
FROM catalog_application') AS T(
    id int,
    name varchar(50),
    description text,
    created_at  timestamp with time zone,
    score int,
    icon varchar(100),
    level varchar(1),
    category int
    );

\echo 'app_catalog_application_available_for_attributes'
\! send_message 'database migration: app_catalog_application_available_for_attributes'
DELETE FROM app_catalog_application_available_for_attributes;
INSERT INTO app_catalog_application_available_for_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, application_id, attribute_id
FROM catalog_application_available_for_attributes') AS T(
    id int,
    application_id int,
    attribute_id int
    );

\echo 'app_catalog_packagesbyproject'
\! send_message 'database migration: app_catalog_packagesbyproject'
DELETE FROM app_catalog_packagesbyproject;
INSERT INTO app_catalog_packagesbyproject
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, packages_to_install, application_id, project_id
FROM catalog_packagesbyproject') AS T(
    id int,
    packages_to_install text,
    application_id int,
    project_id int
    );

\echo 'app_catalog_policy'
\! send_message 'database migration: app_catalog_policy'
DELETE FROM app_catalog_policy;
INSERT INTO app_catalog_policy
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, name, enabled, exclusive, comment
FROM catalog_policy') AS T(
    id int,
    name varchar(50),
    enabled bool,
    exclusive bool,
    comment text
    );

\echo 'app_catalog_policy_excluded_attributes'
\! send_message 'database migration: app_catalog_policy_excluded_attributes'
DELETE FROM app_catalog_policy_excluded_attributes;
INSERT INTO app_catalog_policy_excluded_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, policy_id, attribute_id
FROM catalog_policy_excluded_attributes') AS T(
    id int,
    policy_id int,
    attribute_id int
    );

\echo 'app_catalog_policy_included_attributes'
\! send_message 'database migration: app_catalog_policy_included_attributes'
DELETE FROM app_catalog_policy_included_attributes;
INSERT INTO app_catalog_policy_included_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, policy_id, attribute_id
FROM catalog_policy_included_attributes') AS T(
    id int,
    policy_id int,
    attribute_id int
    );

\echo 'app_catalog_policygroup'
\! send_message 'database migration: app_catalog_policygroup'
DELETE FROM app_catalog_policygroup;
INSERT INTO app_catalog_policygroup
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, priority, policy_id
FROM catalog_policygroup') AS T(
    id int,
    priority int,
    policy_id int
    );

\echo 'app_catalog_policygroup_applications'
\! send_message 'database migration: app_catalog_policygroup_applications'
DELETE FROM app_catalog_policygroup_applications;
INSERT INTO app_catalog_policygroup_applications
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, policygroup_id, application_id
FROM catalog_policygroup_applications') AS T(
    id int,
    policygroup_id int,
    application_id int
    );

\echo 'app_catalog_policygroup_excluded_attributes'
\! send_message 'database migration: app_catalog_policygroup_excluded_attributes'
DELETE FROM app_catalog_policygroup_excluded_attributes;
INSERT INTO app_catalog_policygroup_excluded_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, policygroup_id, attribute_id
FROM catalog_policygroup_excluded_attributes') AS T(
    id int,
    policygroup_id int,
    attribute_id int
    );

\echo 'app_catalog_policygroup_included_attributes'
\! send_message 'database migration: app_catalog_policygroup_included_attributes'
DELETE FROM app_catalog_policygroup_included_attributes;
INSERT INTO app_catalog_policygroup_included_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, policygroup_id, attribute_id
FROM catalog_policygroup_included_attributes') AS T(
    id int,
    policygroup_id int,
    attribute_id int
    );


-- AUTH
\echo 'auth_group'
\! send_message 'database migration: auth_group'
DELETE FROM auth_group;
INSERT INTO auth_group
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name
FROM auth_group') AS T(
    id int,
    name varchar(150)
    );

/*
\echo 'auth_group_permissions'
\! send_message 'database migration: auth_group_permissions'
DELETE FROM auth_group_permissions;
INSERT INTO auth_group_permissions
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    group_id,
    permission_id
FROM auth_group_permissions') AS T(
    id int,
    group_id int,
    permission_id int
    );

\echo 'auth_permission'
\! send_message 'database migration: auth_permission'
DELETE FROM auth_permission;
INSERT INTO auth_permission
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    content_type_id,
    codename
FROM auth_permission') AS T(
    id int,
    name varchar(255),
    content_type_id int,
    codename varchar(250)
    );
*/
\echo 'auth_user'
\! send_message 'database migration: auth_user'
DELETE FROM auth_user;
INSERT INTO auth_user
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    password,
    last_login,
    is_superuser,
    username,
    first_name,
    last_name,
    email,
    is_staff,
    is_active,
    date_joined
FROM auth_user') AS T(
    id int,
    password varchar(128),
    last_login timestamp with time zone,
    is_superuser bool,
    username varchar(150),
    first_name varchar(150),
    last_name  varchar(150),
    email  varchar(254),
    is_staff bool,
    is_active bool,
    date_joined timestamp with time zone
    );

\echo 'auth_user_groups'
\! send_message 'database migration: auth_user_groups'
DELETE FROM auth_user_groups;
INSERT INTO auth_user_groups
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    user_id,
    group_id
FROM auth_user_groups') AS T(
    id int,
    user_id int,
    group_id int
    );

/*
\echo 'auth_user_user_permissions'
\! send_message 'database migration: auth_user_user_permissions'
DELETE FROM auth_user_user_permissions;
INSERT INTO auth_user_user_permissions
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, user_id, permission_id
FROM auth_user_user_permissions') AS T(
    id int,
    user_id int,
    permission_id int
    );
*/

\echo 'authtoken_token'
\! send_message 'database migration: authtoken_token'
DELETE FROM authtoken_token;
INSERT INTO authtoken_token
    SELECT T.*
 FROM dblink('REMOTE', 'select
    key,
    created,
    user_id
FROM authtoken_token') AS T(
    key varchar(40),
    created timestamp with time zone,
    user_id int
    );


-- CLIENT
\echo 'client_computer'
\! send_message 'database migration: client_computer'
DELETE FROM client_computer;
INSERT INTO client_computer
  SELECT
    id,
    uuid,
    status,
    name,
    fqdn,
    created_at,
    updated_at,
    ip_address,
    forwarded_ip_address,
    last_hardware_capture,
    sync_start_date,
    sync_end_date,
    product,
    machine,
    cpu,
    ram,
    storage,
    disks,
    mac_address,
    comment,
    default_logical_device_id,
    project_id,
    sync_user_id
 FROM dblink('REMOTE', 'select
    id,
    uuid,
    status,
    name,
    fqdn,
    created_at,
    updated_at,
    nullif(ip_address, trim(ip_address::varchar(1))),
    nullif(forwarded_ip_address, trim(ip_address::varchar(1))),
    last_hardware_capture,
    sync_start_date,
    sync_end_date,
    product,
    machine,
    cpu,
    ram,
    storage,
    disks,
    mac_address,
    comment,
    default_logical_device_id,
    project_id,
    sync_user_id
FROM server_computer') AS T(
    id int,
    uuid varchar(36),
    status varchar(20),
    name varchar(50),
    fqdn  varchar(255),
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    ip_address inet,
    forwarded_ip_address inet,
    last_hardware_capture timestamp with time zone,
    sync_start_date timestamp with time zone,
    sync_end_date timestamp with time zone,
    product varchar(80),
    machine varchar(1),
    cpu varchar(50),
    ram bigint,
    storage bigint,
    disks smallint,
    mac_address varchar(60),
    comment text,
    default_logical_device_id int,
    project_id int,
    sync_user_id int
    );

\echo 'client_computer_sync_attributes'
\! send_message 'database migration: client_computer_sync_attributes'
DELETE FROM client_computer_sync_attributes;
INSERT INTO client_computer_sync_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, computer_id, attribute_id
FROM server_computer_sync_attributes') AS T(id int, computer_id int, attribute_id int);

\echo 'client_computer_tags'
\! send_message 'database migration: client_computer_tags'
DELETE FROM client_computer_tags;
INSERT INTO client_computer_tags
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, computer_id, serverattribute_id
FROM server_computer_tags') AS T(id int, computer_id int, serverattribute_id int);

\echo 'client_error'
\! send_message 'database migration: client_error'
DELETE FROM client_error;
INSERT INTO client_error
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    created_at,
    description,
    checked,
    computer_id,
    project_id
FROM server_error') AS T(
    id int,
    created_at timestamp with time zone,
    description text,
    checked bool,
    computer_id int,
    project_id int
    );

\echo 'client_fault'
\! send_message 'database migration: client_fault'
DELETE FROM client_fault;
INSERT INTO client_fault
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    created_at,
    result,
    checked,
    computer_id,
    fault_definition_id,
    project_id
FROM server_fault') AS T(
    id int,
    created_at timestamp with time zone,
    result text,
    checked bool,
    computer_id int,
    fault_definition_id int,
    project_id int
    );

\echo 'client_faultdefinition'
\! send_message 'database migration: client_faultdefinition'
DELETE FROM client_faultdefinition;
INSERT INTO client_faultdefinition
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    description,
    enabled,
    language,
    code
FROM server_faultdefinition') AS T(
    id int,
    name varchar(50),
    description text,
    enabled bool,
    language int,
    code text
    );

\echo 'client_faultdefinition_excluded_attributes'
\! send_message 'database migration: client_faultdefinition_excluded_attributes'
DELETE FROM client_faultdefinition_excluded_attributes;
INSERT INTO client_faultdefinition_excluded_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    faultdefinition_id,
    attribute_id
FROM server_faultdefinition_excluded_attributes') AS T(
    id int,
    faultdefinition_id int,
    attribute_id int
    );

\echo 'client_faultdefinition_included_attributes'
\! send_message 'database migration: client_faultdefinition_included_attributes'
DELETE FROM client_faultdefinition_included_attributes;
INSERT INTO client_faultdefinition_included_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    faultdefinition_id,
    attribute_id
FROM server_faultdefinition_included_attributes') AS T(
    id int,
    faultdefinition_id int,
    attribute_id int
    );

\echo 'client_faultdefinition_users'
\! send_message 'database migration: client_faultdefinition_users'
DELETE FROM client_faultdefinition_users;
INSERT INTO client_faultdefinition_users
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    faultdefinition_id,
    userprofile_id
FROM server_faultdefinition_users') AS T(
    id int,
    faultdefinition_id int,
    userprofile_id int
    );

\echo 'client_migration'
\! send_message 'database migration: client_migration'
DELETE FROM client_migration;
INSERT INTO client_migration
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    created_at,
    computer_id,
    project_id
FROM server_migration') AS T(
    id int,
    created_at timestamp with time zone,
    computer_id int,
    project_id int
    );

\echo 'client_notification'
\! send_message 'database migration: client_notification'
DELETE FROM client_notification;
INSERT INTO client_notification
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    created_at,
    message,
    checked
FROM server_notification') AS T(
    id int,
    created_at timestamp with time zone,
    message text,
    checked bool
    );

-- ONLY DELETE client_packagehistory
\echo 'client_packagehistory'
\! send_message 'database migration: client_packagehistory'
DELETE FROM client_packagehistory;

\echo 'client_statuslog'
\! send_message 'database migration: client_statuslog'
DELETE FROM client_statuslog;
INSERT INTO client_statuslog
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    created_at,
    status,
    computer_id
FROM server_statuslog') AS T(
    id int,
    created_at timestamp with time zone,
    status varchar(20),
    computer_id int
    );

\echo 'client_synchronization'
\! send_message 'database migration: client_synchronization'
DELETE FROM client_synchronization;
INSERT INTO client_synchronization
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    created_at,
    created_at,
    null,
    True,
    computer_id,
    project_id,
    user_id
FROM server_synchronization') AS T(
    id int,
    created_at timestamp with time zone,
    start_date timestamp with time zone,
    consumer varchar(50),
    pms_status_ok bool,
    computer_id int,
    project_id int,
    user_id int
    );

\echo 'client_user'
\! send_message 'database migration: client_user'
DELETE FROM client_user;
INSERT INTO client_user
    SELECT T.* FROM dblink('REMOTE', 'select * FROM server_user') AS T(id int, name varchar(50),fullname varchar(100));


-- CORE
\echo 'core_attribute'
\! send_message 'database migration: core_attribute'
DELETE FROM core_attribute;
INSERT INTO core_attribute
    SELECT T.id, T.value, T.description, T.longitude, T.latitude, T.property_att
 FROM dblink('REMOTE', 'select
        server_attribute.id,
        server_attribute.value,
        server_attribute.description,
        null,
        null,
        server_attribute.property_att_id
FROM server_attribute') AS T(id int, value varchar(250), description text, longitude double precision, latitude double precision, property_att int );

\echo 'core_attributeset'
\! send_message 'database migration: core_attributeset'
DELETE FROM core_attributeset;
INSERT INTO core_attributeset
    SELECT T.*
 FROM dblink('REMOTE', 'select
        id,
        name,
        description,
        enabled,
        0,
        0
FROM server_attributeset') AS T(id int, name varchar(50), description text, enabled bool, longitude double precision, latitude double precision);

\echo 'core_attributeset_excluded_attributes'
\! send_message 'database migration: core_attributeset_excluded_attributes'
DELETE FROM core_attributeset_excluded_attributes;
INSERT INTO core_attributeset_excluded_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    *
FROM server_attributeset_excluded_attributes') AS T(id int, attributeset_id int, attribute_id int);

\echo 'core_attributeset_included_attributes'
\! send_message 'database migration: core_attributeset_included_attributes'
DELETE FROM core_attributeset_included_attributes;
INSERT INTO core_attributeset_included_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    *
FROM server_attributeset_included_attributes') AS T(id int, attributeset_id int, attribute_id int);


-- TODO DEPLOYMENT
\echo 'core_deployment'
\! send_message 'database migration: core_deployment'
DELETE FROM core_deployment;
INSERT INTO core_deployment
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    enabled,
    name,
    name,
    comment,
    packages_to_install,
    packages_to_remove,
    start_date,
    default_preincluded_packages,
    default_included_packages,
    default_excluded_packages,
    source,
    base_url,
    options,
    suite,
    components,
    frozen,
    expire,
    domain_id,
    project_id,
    schedule_id
FROM server_deployment') AS T(
    id integer,
    enabled bool,
    name varchar(50),
    slug varchar(50),
    comment text,
    packages_to_install text,
    packages_to_remove text,
    start_date date,
    default_preincluded_packages text,
    default_included_packages text,
    default_excluded_packages text,
    source varchar(1),
    base_url varchar(100),
    options varchar(250),
    suite varchar(50),
    components varchar(100),
    frozen bool,
    expire int,
    domain_id int,
    project_id int,
    schedule_id int
    );

\echo 'core_deployment_available_packages'
\! send_message 'database migration: core_deployment_available_packages'
DELETE FROM core_deployment_available_packages;
INSERT INTO core_deployment_available_packages
    SELECT T.*
 FROM dblink('REMOTE', 'select
    A.id,
    A.deployment_id,
    A.package_id
FROM server_deployment_available_packages AS A
INNER JOIN server_package AS P ON P.id=A.package_id
        WHERE
                P.name  like ''%.deb''
                OR P.name like ''%.rpm''
                OR P.name like ''%.exe''
                OR P.name like ''%.gip''
') AS T(
    id int,
    deployment_id int,
    package_id int
    );

\echo 'core_deployment_available_package_sets'
\! send_message 'database migration: core_deployment_available_package_sets'
DELETE FROM core_deployment_available_package_sets;
INSERT INTO core_deployment_available_package_sets
    SELECT T.*
 FROM dblink('REMOTE', 'select
    A.id,
    A.deployment_id,
    A.package_id
FROM server_deployment_available_packages AS A
INNER JOIN server_package AS P ON P.id=A.package_id
        WHERE NOT (
                P.name  like ''%.deb''
                OR P.name like ''%.rpm''
                OR P.name like ''%.exe''
                OR P.name like ''%.gip''
                )
') AS T(
    id int,
    deployment_id int,
    packageset_id int
    );

\echo 'core_deployment_excluded_attributes'
\! send_message 'database migration: core_deployment_excluded_attributes'
DELETE FROM core_deployment_excluded_attributes;
INSERT INTO core_deployment_excluded_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    deployment_id,
    attribute_id
FROM server_deployment_excluded_attributes') AS T(
    id int,
    deployment_id int,
    attribute_id int
    );

\echo 'core_deployment_included_attributes'
\! send_message 'database migration: core_deployment_included_attributes'
DELETE FROM core_deployment_included_attributes;
INSERT INTO core_deployment_included_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    deployment_id,
    attribute_id
FROM server_deployment_included_attributes') AS T(
    id int,
    deployment_id int,
    attribute_id int
    );

\echo 'core_domain'
\! send_message 'database migration: core_domain'
DELETE FROM core_domain;
INSERT INTO core_domain
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    comment
FROM server_domain') AS T(
    id int,
    name varchar(50),
    comment text
    );

\echo 'core_domain_excluded_attributes'
\! send_message 'database migration: core_domain_excluded_attributes'
DELETE FROM core_domain_excluded_attributes;
INSERT INTO core_domain_excluded_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    domain_id,
    attribute_id
FROM server_domain_excluded_attributes') AS T(
    id int,
    domain_id int,
    attribute_id int
    );

\echo 'core_domain_included_attributes'
\! send_message 'database migration: core_domain_included_attributes'
DELETE FROM core_domain_included_attributes;
INSERT INTO core_domain_included_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    domain_id,
    attribute_id
FROM server_domain_included_attributes') AS T(
    id int,
    domain_id int,
    attribute_id int
    );

\echo 'core_domain_tags'
\! send_message 'database migration: core_domain_tags'
DELETE FROM core_domain_tags;
INSERT INTO core_domain_tags
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    domain_id,
    serverattribute_id
FROM server_domain_tags') AS T(
    id int,
    domain_id int,
    serverattribute_id int
    );

\echo 'core_package'
\! send_message 'database migration: core_package'
DELETE FROM core_package;
INSERT INTO core_package
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    '''',
    '''',
    '''',
    project_id,
    store_id
FROM server_package
        WHERE
                name  like ''%.deb''
                OR name like ''%.rpm''
                OR name like ''%.exe''
                OR name like ''%.gip''
                 ') AS T(
    id int,
    fullname varchar(170),
    name varchar(100),
    version varchar(60),
    architecture varchar(10),
    project_id int,
    store_id int
    );

\echo 'core_packageset'
\! send_message 'database migration: core_packageset'
DELETE FROM core_packageset;
INSERT INTO core_packageset
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    '''',
    project_id,
    store_id
FROM server_package
        WHERE not (
                name  like ''%.deb''
                OR name like ''%.rpm''
                OR name like ''%.exe''
                OR name like ''%.gip'' )
                 ') AS T(
    id int,
    name varchar(50),
    description text,
    project_id int,
    store_id int
    );

\echo 'core_platform'
\! send_message 'database migration: core_platform'
DELETE FROM core_platform;
INSERT INTO core_platform
    SELECT T.* FROM dblink('REMOTE', 'select * FROM server_platform') AS T(id int, name varchar(50));

-- TODO Revisar campo "slug" y "pms"
\echo 'core_project'
\! send_message 'database migration: core_project'
DELETE FROM core_project;
INSERT INTO core_project
    SELECT T.id,T.name,T.name,T.pms,'amd64',T.auto_register_computers,T.platform FROM dblink('REMOTE',
        'select
                server_project.id,
                server_project.name,
                server_project.name,
                server_pms.name,
                coalesce(server_project.auto_register_computers, FALSE),
                server_project.platform_id
                FROM server_project INNER JOIN server_pms
                ON server_pms.id=server_project.pms_id ') AS T(
                        id int,
                        name varchar(50),
                        slug varchar(50),
                        pms varchar(50),
                        auto_register_computers bool,
                        platform int);

\echo 'core_property'
DELETE FROM core_property;
INSERT INTO core_property
    SELECT *
 FROM dblink('REMOTE', 'select
        server_property.id,
        server_property.prefix,
        server_property.name,
        server_property.enabled,
        server_property.kind,
        server_property.sort,
        server_property.auto_add,
        server_property.language,
        server_property.code
 FROM server_property') AS T(id int, prefix varchar(3), name varchar(50), enabled bool, kind varchar(1), sort varchar(10),auto_add bool, language int,code text);

\echo 'core_schedule'
\! send_message 'database migration: core_schedule'
DELETE FROM core_schedule;
INSERT INTO core_schedule
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    description
FROM server_schedule') AS T(
    id int,
    name varchar(50),
    description text
    );

\echo 'core_scheduledelay'
\! send_message 'database migration: core_scheduledelay'
DELETE FROM core_scheduledelay;
INSERT INTO core_scheduledelay
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    delay,
    duration,
    schedule_id
FROM server_scheduledelay') AS T(
    id int,
    delay int,
    duration int,
    schedule_id int
    );

\echo 'core_scheduledelay_attributes'
\! send_message 'database migration: core_scheduledelay_attributes'
DELETE FROM core_scheduledelay_attributes;
INSERT INTO core_scheduledelay_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    scheduledelay_id,
    attribute_id
FROM server_scheduledelay_attributes') AS T(
    id int,
    scheduledelay_id int,
    attribute_id int
    );

\echo 'core_scope'
\! send_message 'database migration: core_scope'
DELETE FROM core_scope;
INSERT INTO core_scope
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    domain_id,
    user_id
FROM server_scope') AS T(
    id int,
    name varchar(50),
    domain_id int,
    user_id int
    );

\echo 'core_scope_excluded_attributes'
\! send_message 'database migration: core_scope_excluded_attributes'
DELETE FROM core_scope_excluded_attributes;
INSERT INTO core_scope_excluded_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    scope_id,
    attribute_id
FROM server_scope_excluded_attributes') AS T(
    id int,
    scope_id int,
    attribute_id int
    );

\echo 'core_scope_included_attributes'
\! send_message 'database migration: core_scope_included_attributes'
DELETE FROM core_scope_included_attributes;
INSERT INTO core_scope_included_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    scope_id,
    attribute_id
FROM server_scope_included_attributes') AS T(
    id int,
    scope_id int,
    attribute_id int
    );

\echo 'core_store'
\! send_message 'database migration: core_store'
DELETE FROM core_store;
INSERT INTO core_store
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    name,
    project_id
FROM server_store') AS T(
    id int,
    name varchar(50),
    slug varchar(50),
    project_id int
    );

\echo 'core_userprofile'
\! send_message 'database migration: core_userprofile'
DELETE FROM core_userprofile;
INSERT INTO core_userprofile
    SELECT T.*
 FROM dblink('REMOTE', 'select
    user_ptr_id,
    domain_preference_id,
    scope_preference_id
FROM server_userprofile') AS T(
    user_ptr_id int,
    domain_preference_id int,
    scope_preference_id int
    );

\echo 'core_userprofile_domains'
\! send_message 'database migration: core_userprofile_domains'
DELETE FROM core_userprofile_domains;
INSERT INTO core_userprofile_domains
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    userprofile_id,
    domain_id
FROM server_userprofile_domains') AS T(
    id int,
    userprofile_id int,
    domain_id int
    );

--   DEVICES
\echo 'device_capability'
\! send_message 'database migration: device_capability'
DELETE FROM device_capability;
INSERT INTO device_capability
    SELECT T.*
 FROM dblink('REMOTE', 'select
    *
FROM server_devicefeature') AS T(id int, name varchar(50));

\echo 'device_connection'
\! send_message 'database migration: device_connection'
DELETE FROM device_connection;
INSERT INTO device_connection
    SELECT T.*
 FROM dblink('REMOTE', 'select
    *
FROM server_deviceconnection') AS T(id int, name varchar(50), fields varchar(100), device_type_id int);

\echo 'device_device'
\! send_message 'database migration: device_device'
DELETE FROM device_device;
INSERT INTO device_device
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, name, data, connection_id, model_id
FROM server_device') AS T(id int, name varchar(50), data text, connection_id int, model_id int);

\echo 'device_device_available_for_attributes'
\! send_message 'database migration: device_device_available_for_attributes'
DELETE FROM device_device_available_for_attributes;
INSERT INTO device_device_available_for_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, device_id, attribute_id
FROM server_device_available_for_attributes') AS T(id int, device_id int, attribute_id int);

\echo 'device_driver'
\! send_message 'database migration: device_driver'
DELETE FROM device_driver;
INSERT INTO device_driver
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, name, packages_to_install, feature_id, model_id, project_id
FROM server_devicedriver') AS T(id int, name varchar(100), packages_to_install text,capability_id int, model_id int, project_id int);

\echo 'device_logical'
\! send_message 'database migration: device_logical'
DELETE FROM device_logical;
INSERT INTO device_logical
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, alternative_feature_name, feature_id, device_id
FROM server_devicelogical') AS T(id int, alternative_capability_name varchar(50), capability_id int, device_id int);

\echo 'device_logical_attributes'
\! send_message 'database migration: device_logical_attributes'
DELETE FROM device_logical_attributes;
INSERT INTO device_logical_attributes
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, devicelogical_id, attribute_id
FROM server_devicelogical_attributes') AS T(id int, logical_id int, attribute_id int);

\echo 'device_manufacturer'
\! send_message 'database migration: device_manufacturer'
DELETE FROM device_manufacturer;
INSERT INTO device_manufacturer
    SELECT T.*
 FROM dblink('REMOTE', 'select
    *
FROM server_devicemanufacturer') AS T(id int, name varchar(50));

\echo 'device_model'
\! send_message 'database migration: device_model'
DELETE FROM device_model;
INSERT INTO device_model
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id, name,device_type_id, manufacturer_id
FROM server_devicemodel') AS T(id int, name varchar(50), device_type_id int, manufacter_id int);

\echo 'device_model_connections'
\! send_message 'database migration: device_model_connections'
DELETE FROM device_model_connections;
INSERT INTO device_model_connections
    SELECT T.*
 FROM dblink('REMOTE', 'select
    *
FROM server_devicemodel_connections') AS T(id int, model_id int, connection_id int);

\echo 'device_type'
\! send_message 'database migration: device_type'
DELETE FROM device_type;
INSERT INTO device_type
    SELECT T.*
 FROM dblink('REMOTE', 'select
    *
FROM server_devicetype') AS T(id int, name varchar(50));


-- HARDWARE
\echo 'hardware_capability'
\! send_message 'database migration: hardware_capability'
DELETE FROM hardware_capability;
INSERT INTO hardware_capability
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    description,
    node_id
FROM server_hwcapability') AS T(
    id int,
    name text,
    description text,
    node_id int
    );

\echo 'hardware_configuration'
\! send_message 'database migration: hardware_configuration'
DELETE FROM hardware_configuration;
INSERT INTO hardware_configuration
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    value,
    node_id
FROM server_hwconfiguration') AS T(
    id int,
    name text,
    value text,
    node_id int
    );

\echo 'hardware_logicalname'
\! send_message 'database migration: hardware_logicalname'
DELETE FROM hardware_logicalname;
INSERT INTO hardware_logicalname
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    name,
    node_id
FROM server_hwlogicalname') AS T(
    id int,
    name text,
    node_id int
    );

\echo 'hardware_node'
\! send_message 'database migration: hardware_node'
DELETE FROM hardware_node;
INSERT INTO hardware_node
    SELECT T.*
 FROM dblink('REMOTE', 'select
    id,
    level,
    width,
    name,
    class_name,
    enabled,
    claimed,
    description,
    vendor,
    product,
    version,
    serial,
    bus_info,
    physid,
    slot,
    size,
    capacity,
    clock,
    dev,
    computer_id,
    parent_id
FROM server_hwnode') AS T(
    id int,
    level int,
    width bigint,
    name text,
    class_name text,
    enabled bool,
    claimed bool,
    description text,
    vendor text,
    product text,
    version text,
    serial text,
    bus_info text,
    physid text,
    slot text,
    size bigint,
    capacity bigint,
    clock bigint,
    dev text,
    computer_id int,
    parent_id int
    );


SET session_replication_role TO 'origin';
\echo 'reindex database'
\! send_message 'database migration: reindex database'
REINDEX DATABASE migasfree;

\echo 'vacuum database'
\! send_message 'database migration: vacuum database'
VACUUM FULL FREEZE ANALYZE;

/*
===================
RESET ALL SEQUENCES
===================
https://tapoueh.org/blog/2010/02/resetting-sequences.-all-of-them-please/
SELECT 'select '
        || trim(trailing ')'
           from replace(pg_get_expr(d.adbin, d.adrelid),
                        'nextval', 'setval'))
        || ', (select max( ' || a.attname || ') from only '
        || nspname || '.' || relname || '));'
  FROM pg_class c
       JOIN pg_namespace n on n.oid = c.relnamespace
       JOIN pg_attribute a on a.attrelid = c.oid
       JOIN pg_attrdef d on d.adrelid = a.attrelid
                          and d.adnum = a.attnum
                          and a.atthasdef
 WHERE relkind = 'r' and a.attnum > 0
       and pg_get_expr(d.adbin, d.adrelid) ~ '^nextval';

*/

\echo 'resetting sequences'
\! send_message 'database migration: resetting sequences'

 select setval('django_migrations_id_seq'::regclass, (select max( id) from only public.django_migrations));
 select setval('django_content_type_id_seq'::regclass, (select max( id) from only public.django_content_type));
 select setval('auth_permission_id_seq'::regclass, (select max( id) from only public.auth_permission));
 select setval('auth_group_id_seq'::regclass, (select max( id) from only public.auth_group));
 select setval('auth_group_permissions_id_seq'::regclass, (select max( id) from only public.auth_group_permissions));
 select setval('auth_user_id_seq'::regclass, (select max( id) from only public.auth_user));
 select setval('auth_user_groups_id_seq'::regclass, (select max( id) from only public.auth_user_groups));
 select setval('auth_user_user_permissions_id_seq'::regclass, (select max( id) from only public.auth_user_user_permissions));
 select setval('django_admin_log_id_seq'::regclass, (select max( id) from only public.django_admin_log));
 select setval('core_attribute_id_seq'::regclass, (select max( id) from only public.core_attribute));
 select setval('core_domain_id_seq'::regclass, (select max( id) from only public.core_domain));
 select setval('core_domain_excluded_attributes_id_seq'::regclass, (select max( id) from only public.core_domain_excluded_attributes));
 select setval('core_domain_included_attributes_id_seq'::regclass, (select max( id) from only public.core_domain_included_attributes));
 select setval('core_package_id_seq'::regclass, (select max( id) from only public.core_package));
 select setval('core_platform_id_seq'::regclass, (select max( id) from only public.core_platform));
 select setval('core_project_id_seq'::regclass, (select max( id) from only public.core_project));
 select setval('core_property_id_seq'::regclass, (select max( id) from only public.core_property));
 select setval('core_schedule_id_seq'::regclass, (select max( id) from only public.core_schedule));
 select setval('core_scope_id_seq'::regclass, (select max( id) from only public.core_scope));
 select setval('core_scope_excluded_attributes_id_seq'::regclass, (select max( id) from only public.core_scope_excluded_attributes));
 select setval('core_scope_included_attributes_id_seq'::regclass, (select max( id) from only public.core_scope_included_attributes));
 select setval('core_userprofile_domains_id_seq'::regclass, (select max( id) from only public.core_userprofile_domains));
 select setval('core_store_id_seq'::regclass, (select max( id) from only public.core_store));
 select setval('core_packageset_id_seq'::regclass, (select max( id) from only public.core_packageset));
 select setval('core_packageset_packages_id_seq'::regclass, (select max( id) from only public.core_packageset_packages));
 select setval('core_deployment_id_seq'::regclass, (select max( id) from only public.core_deployment));
 select setval('core_deployment_available_package_sets_id_seq'::regclass, (select max( id) from only public.core_deployment_available_package_sets));
 select setval('core_deployment_available_packages_id_seq'::regclass, (select max( id) from only public.core_deployment_available_packages));
 select setval('core_deployment_excluded_attributes_id_seq'::regclass, (select max( id) from only public.core_deployment_excluded_attributes));
 select setval('core_deployment_included_attributes_id_seq'::regclass, (select max( id) from only public.core_deployment_included_attributes));
 select setval('core_attributeset_id_seq'::regclass, (select max( id) from only public.core_attributeset));
 select setval('core_attributeset_excluded_attributes_id_seq'::regclass, (select max( id) from only public.core_attributeset_excluded_attributes));
 select setval('core_attributeset_included_attributes_id_seq'::regclass, (select max( id) from only public.core_attributeset_included_attributes));
 select setval('core_scheduledelay_id_seq'::regclass, (select max( id) from only public.core_scheduledelay));
 select setval('core_scheduledelay_attributes_id_seq'::regclass, (select max( id) from only public.core_scheduledelay_attributes));
 select setval('core_domain_tags_id_seq'::regclass, (select max( id) from only public.core_domain_tags));
 select setval('app_catalog_application_id_seq'::regclass, (select max( id) from only public.app_catalog_application));
 select setval('app_catalog_application_available_for_attributes_id_seq'::regclass, (select max( id) from only public.app_catalog_application_available_for_attributes));
 select setval('app_catalog_policy_id_seq'::regclass, (select max( id) from only public.app_catalog_policy));
 select setval('app_catalog_policy_excluded_attributes_id_seq'::regclass, (select max( id) from only public.app_catalog_policy_excluded_attributes));
 select setval('app_catalog_policy_included_attributes_id_seq'::regclass, (select max( id) from only public.app_catalog_policy_included_attributes));
 select setval('app_catalog_policygroup_id_seq'::regclass, (select max( id) from only public.app_catalog_policygroup));
 select setval('app_catalog_policygroup_applications_id_seq'::regclass, (select max( id) from only public.app_catalog_policygroup_applications));
 select setval('app_catalog_policygroup_excluded_attributes_id_seq'::regclass, (select max( id) from only public.app_catalog_policygroup_excluded_attributes));
 select setval('app_catalog_policygroup_included_attributes_id_seq'::regclass, (select max( id) from only public.app_catalog_policygroup_included_attributes));
 select setval('app_catalog_packagesbyproject_id_seq'::regclass, (select max( id) from only public.app_catalog_packagesbyproject));
 select setval('device_capability_id_seq'::regclass, (select max( id) from only public.device_capability));
 select setval('device_connection_id_seq'::regclass, (select max( id) from only public.device_connection));
 select setval('device_manufacturer_id_seq'::regclass, (select max( id) from only public.device_manufacturer));
 select setval('device_type_id_seq'::regclass, (select max( id) from only public.device_type));
 select setval('device_model_id_seq'::regclass, (select max( id) from only public.device_model));
 select setval('device_model_connections_id_seq'::regclass, (select max( id) from only public.device_model_connections));
 select setval('device_device_id_seq'::regclass, (select max( id) from only public.device_device));
 select setval('device_device_available_for_attributes_id_seq'::regclass, (select max( id) from only public.device_device_available_for_attributes));
 select setval('device_logical_id_seq'::regclass, (select max( id) from only public.device_logical));
 select setval('device_logical_attributes_id_seq'::regclass, (select max( id) from only public.device_logical_attributes));
 select setval('device_driver_id_seq'::regclass, (select max( id) from only public.device_driver));
 select setval('client_computer_id_seq'::regclass, (select max( id) from only public.client_computer));
 select setval('client_computer_sync_attributes_id_seq'::regclass, (select max( id) from only public.client_computer_sync_attributes));
 select setval('client_notification_id_seq'::regclass, (select max( id) from only public.client_notification));
 select setval('client_user_id_seq'::regclass, (select max( id) from only public.client_user));
 select setval('client_synchronization_id_seq'::regclass, (select max( id) from only public.client_synchronization));
 select setval('client_statuslog_id_seq'::regclass, (select max( id) from only public.client_statuslog));
 select setval('client_packagehistory_id_seq'::regclass, (select max( id) from only public.client_packagehistory));
 select setval('client_migration_id_seq'::regclass, (select max( id) from only public.client_migration));
 select setval('client_faultdefinition_id_seq'::regclass, (select max( id) from only public.client_faultdefinition));
 select setval('client_faultdefinition_excluded_attributes_id_seq'::regclass, (select max( id) from only public.client_faultdefinition_excluded_attributes));
 select setval('client_faultdefinition_included_attributes_id_seq'::regclass, (select max( id) from only public.client_faultdefinition_included_attributes));
 select setval('client_faultdefinition_users_id_seq'::regclass, (select max( id) from only public.client_faultdefinition_users));
 select setval('client_fault_id_seq'::regclass, (select max( id) from only public.client_fault));
 select setval('client_error_id_seq'::regclass, (select max( id) from only public.client_error));
 select setval('client_computer_tags_id_seq'::regclass, (select max( id) from only public.client_computer_tags));
 select setval('hardware_node_id_seq'::regclass, (select max( id) from only public.hardware_node));
 select setval('hardware_logicalname_id_seq'::regclass, (select max( id) from only public.hardware_logicalname));
 select setval('hardware_configuration_id_seq'::regclass, (select max( id) from only public.hardware_configuration));
 select setval('hardware_capability_id_seq'::regclass, (select max( id) from only public.hardware_capability));

\echo 'finished'
\! send_message 'database migration: finished'
