#       Copyright 2017-2021 IBM Corp All Rights Reserved

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

FROM maven:3.6-jdk-11-slim AS build
COPY . /usr/
RUN mvn -f /usr/pom.xml clean package

# FROM websphere-liberty:microProfile3
FROM openliberty/open-liberty:kernel-slim-java11-openj9-ubi

USER root

COPY --from=build /usr/src/main/liberty/config /config/

#Workaround for https://github.com/OpenLiberty/ci.docker/issues/244
RUN touch /config/server.xml

# This script will add the requested XML snippets to enable Liberty features and grow image to be fit-for-purpose using featureUtility. 
# Only available in 'kernel-slim'. The 'full' tag already includes all features for convenience.
RUN features.sh

COPY --from=build /usr/messaging-ear/target/messaging-ear-1.0-SNAPSHOT.ear /config/apps/Messaging.ear
COPY --from=build /usr/messaging-ear/target/prereqs/wmq.jmsra-9.2.1.0.rar /config/wmq.jmsra.rar

RUN chown -R 1001:0 /config/
USER 1001

RUN configure.sh
