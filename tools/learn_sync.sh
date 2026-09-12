#!/bin/sh
# Pull Open edX completions into MagiMDM outcomes.
# v1: prints enrollments that still need a grade.
set -eu
DB=${ZIGMDM_DB:-data/mdm.db}
echo "# enrollments missing outcomes"
sqlite3 -header -column "$DB" "
SELECT c.code, ch.given_name, e.id
  FROM enrollments e
  JOIN courses c ON c.id = e.course_id
  JOIN children ch ON ch.id = e.child_id
 WHERE e.id NOT IN (SELECT enrollment_id FROM outcomes)
"
echo "# set LEARN_URL and use Open edX API here when Tutor is up"
