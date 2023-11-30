# En Linux ejecutando un demonio
FROM mcr.microsoft.com/dotnet/aspnet:7.0.4-bullseye-slim-amd64
WORKDIR /POC.OTEL.Web

RUN mkdir log

#COPY ..\net5.0 .

#run powershell [Environment]::SetEnvironmentVariable('TNS_ADMIN', 'C:\MessageConverter', 'Machine')

RUN echo "Aquí tienen que salir los logs" > ./log/Leeme.txt
RUN ls
RUN pwd

RUN apt-get update && apt-get install -y procps && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y curl 
RUN apt-get update && apt-get install -y vim
#RUN apt-get install sudo

#OpenTelemetry
# ARG OTEL_VERSION=0.7.0
# ADD https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/v${OTEL_VERSION}/otel-dotnet-auto-install.sh otel-dotnet-auto-install.sh
# RUN apt-get update & apt-get install -y unzip && \
# 	OTEL_DOTNET_AUTO_HOME="/otel-dotnet-auto" sh otel-dotnet-auto-install.sh

ADD poc.otel.web.tar.gz  .

# RUN curl "http://rabbitmq-t.dof6.com:15672/#/queues/crm-vhost/codificacion.conf.publi.des" -i

RUN chmod +x POC.OTEL.20231020.Web

#RUN ./MovistarPlus.MessageConverter
#RUN bash
ENTRYPOINT ["./POC.OTEL.20231020.Web"]

#RUN sc.exe create MovistarPlus.MessageConverter binpath=C:\MessageConverter\MovistarPlus.MessageConverter.exe
#RUN powershell start-service MovistarPlus.MessageConverter
#RUN powershell set-service MovistarPlus.MessageConverter -StartupType Automatic
#RUN while true; do sleep 1000; done

#CMD powershell start-service SynchroFileRobocopyGuiaFacil 
#CMD powershell get-service SynchroFileRobocopyGuiaFacil 
