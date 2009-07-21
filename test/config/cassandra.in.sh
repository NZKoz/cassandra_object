CASSANDRA_HOME=`dirname $0`/..

CLASSPATH=$CASSANDRA_CONF:$CASSANDRA_HOME/build/classes

for jar in $CASSANDRA_HOME/lib/*.jar; do
  CLASSPATH=$CLASSPATH:$jar
done

JVM_OPTS=" \
        -ea \
        -Xdebug \
        -Xrunjdwp:transport=dt_socket,server=y,address=8888,suspend=n \
        -Xms128M \
        -Xmx1G \
        -XX:SurvivorRatio=8 \
        -XX:TargetSurvivorRatio=90 \
        -XX:+AggressiveOpts \
        -XX:+UseParNewGC \
        -XX:+UseConcMarkSweepGC \
        -XX:CMSInitiatingOccupancyFraction=1 \
        -XX:+CMSParallelRemarkEnabled \
        -XX:+HeapDumpOnOutOfMemoryError \
        -Dcom.sun.management.jmxremote.port=8080 \
        -Dcom.sun.management.jmxremote.ssl=false \
        -Dcom.sun.management.jmxremote.authenticate=false"
