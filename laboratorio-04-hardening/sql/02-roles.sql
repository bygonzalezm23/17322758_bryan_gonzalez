SELECT
    rolname,
    rolsuper,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles
ORDER BY rolname;

SELECT
    extname,
    extversion
FROM pg_extension
ORDER BY extname;

