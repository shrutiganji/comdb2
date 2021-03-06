#!/usr/bin/env bash

if [ $SP_HOST != `hostname` ]; then
  ssh $SP_HOST mkdir -p $DBDIR/rulesets/
  scp *.ruleset $SP_HOST:$DBDIR/rulesets/
fi

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 0' AS z;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')"

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 1' AS z;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 1;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT * FROM t1 ORDER BY x;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT x FROM t1 ORDER BY x;" 2>&1

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 2' AS z;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "PUT TUNABLE 'debug.thdpool_queue_only' 1"

if [[ $DBNAME == *"nofpgenerated"* ]] ; then
  cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t01.ruleset')" 2>&1 | sed 's/\[ERROR\] .*t01.ruleset/\[ERROR\] t01.ruleset/g'
else
  cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t01.ruleset')" 2>&1 | sed 's/file ".*"/file "t01.ruleset"/g'
fi

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 3' AS z;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 2;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT * FROM t1 ORDER BY x;" 2>&1

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT x FROM t1 ORDER BY x;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "CREATE TABLE txx(bad TEXT);" 2>&1

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 4' AS z;" 2>&1

if [[ $DBNAME != *"nofpgenerated"* ]] ; then
  cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('save_ruleset $DBDIR/rulesets/t01_saved.ruleset')" | sed 's/file ".*"/file "t01_saved.ruleset"/g'
  cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('save_ruleset $DBDIR/rulesets/t02_saved.ruleset')" | sed 's/file ".*"/file "t02_saved.ruleset"/g'

  if [ $SP_HOST != `hostname` ]; then
    scp $SP_HOST:$DBDIR/rulesets/t01_saved.ruleset $DBDIR/rulesets/t01_saved.ruleset
    scp $SP_HOST:$DBDIR/rulesets/t02_saved.ruleset $DBDIR/rulesets/t02_saved.ruleset
  fi

  if ! diff $DBDIR/rulesets/t01.ruleset $DBDIR/rulesets/t01_saved.ruleset ; then
    echo output for t01_saved.ruleset is different from expected
    exit 1
  fi

  if ! diff $DBDIR/rulesets/t01.ruleset $DBDIR/rulesets/t02_saved.ruleset ; then
    echo output for t02_saved.ruleset is different from expected
    exit 1
  fi
fi

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('evaluate_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 5' AS z;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t00.ruleset')" 2>&1 | sed 's/file ".*"/file "t00.ruleset"/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 6' AS z;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 3;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT * FROM t1 ORDER BY x;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT x FROM t1 ORDER BY x;" 2>&1

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('evaluate_ruleset')"

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 7' AS z;" 2>&1

if [[ $DBNAME == *"nofpgenerated"* ]] ; then
  cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t01.ruleset')" 2>&1 | sed 's/\[ERROR\] .*t01.ruleset/\[ERROR\] t01.ruleset/g'
else
  cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t01.ruleset')" 2>&1 | sed 's/file ".*"/file "t01.ruleset"/g'
fi

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/bad.ruleset')" 2>&1 | sed 's/\[ERROR\] .*bad.ruleset/\[ERROR\] bad.ruleset/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('evaluate_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('enable_ruleset_item 1 0')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('evaluate_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('enable_ruleset_item 1 1')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('evaluate_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 8' AS z;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t03.ruleset')" 2>&1 | sed 's/file ".*"/file "t03.ruleset"/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 9' AS z;" 2>&1

if [[ $DBNAME == *"nofpgenerated"* ]] ; then
  cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t01.ruleset')" 2>&1 | sed 's/\[ERROR\] .*t01.ruleset/\[ERROR\] t01.ruleset/g'
else
  cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t01.ruleset')" 2>&1 | sed 's/file ".*"/file "t01.ruleset"/g'
fi

cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t02.ruleset')" 2>&1 | sed 's/file ".*"/file "t02.ruleset"/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"

cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT 'phase 10' AS z;" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('reload_ruleset $DBDIR/rulesets/t04.ruleset')" 2>&1 | sed 's/file ".*"/file "t04.ruleset"/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "PUT TUNABLE 'debug.thdpool_queue_only' 0"
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT sleep(1);" 2>&1
cdb2sql --host $SP_HOST $SP_OPTIONS "SELECT comdb2_host();" 2>&1 | sed 's/\x27.*\x27/host_name_here/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('dump_ruleset')" | sed 's/ruleset 0x[0-9A-Fa-f]\+/ruleset 0x00000000/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('free_ruleset')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('list_sql_pools')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('destroy_sql_pool extra1')" | sed 's/[0-9]\+ microseconds/X microseconds/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('destroy_sql_pool extra2')" | sed 's/[0-9]\+ microseconds/X microseconds/g'
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('destroy_sql_pool extra3')"
cdb2sql --host $SP_HOST $SP_OPTIONS "EXEC PROCEDURE sys.cmd.send('destroy_sql_pool extra4')" | sed 's/[0-9]\+ microseconds/X microseconds/g'
