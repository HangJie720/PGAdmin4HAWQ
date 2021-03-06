{% if (vid and datlastsysoid) or scid %}
SELECT
    c.oid,
    c.xmin,
    (CASE WHEN length(spc.spcname) > 0 THEN spc.spcname ELSE 'pg_default' END) as spcname,
    c.relname AS name,
    nsp.nspname AS schema,
    description AS comment,
    c.reltablespace AS spcoid,
    pg_get_userbyid(c.relowner) AS owner,
    pg_get_viewdef(c.oid, true) AS definition,
    array_to_string(c.relacl, ', ') AS acl,
    {#=============Checks if it is system view================#}
    {% if vid and datlastsysoid %}
    CASE WHEN {{vid}} <= {{datlastsysoid}} THEN True ELSE False END AS system_view,
    {% endif %}
    NULL::text[] AS seclabels
FROM pg_class c
    LEFT OUTER JOIN pg_namespace nsp on nsp.oid = c.relnamespace
    LEFT OUTER JOIN pg_tablespace spc on spc.oid=c.reltablespace
    LEFT OUTER JOIN pg_description des ON (des.objoid=c.oid and des.objsubid=0 AND des.classoid='pg_class'::regclass)
WHERE ((c.relhasrules
            AND
                (EXISTS(
                    SELECT
                        r.rulename
                    FROM
                        pg_rewrite r
                    WHERE
                        ((r.ev_class = c.oid) AND (bpchar(r.ev_type) = '1'::bpchar))
                ))
       ) AND (c.relkind = 'v'::char))
{% if (vid and datlastsysoid) %}
    AND c.oid = {{vid}}::oid
{% elif scid %}
    AND c.relnamespace = {{scid}}::oid ORDER BY c.relname
{% endif %}

{% elif type == 'roles' %}
SELECT
    pr.rolname
FROM
    pg_roles pr
WHERE
    pr.rolcanlogin
ORDER BY
    pr.rolname

{% elif type == 'schemas' %}
SELECT
    nsp.nspname
FROM
    pg_namespace nsp
WHERE
    (nsp.nspname NOT LIKE E'pg\\_%'
        AND nsp.nspname != 'information_schema')
{% endif %}
