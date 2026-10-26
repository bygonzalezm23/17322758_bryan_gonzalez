SHOW data_directory;
SHOW config_file;
SHOW hba_file;

SHOW ssl;
SHOW ssl_min_protocol_version;

SELECT
    pid,
    ssl,
    version,
    cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();