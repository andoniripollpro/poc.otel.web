
#*******   ES LINUX   *******
"`n-->Comprobaciones con DockerRepository y oc "

$dockerInfoOutput =  docker push andonicacharreo.jfrog.io/docker/poc_otel_web
if ($dockerInfoOutput -like '*andonicacharreo.jfrog.io*') {
    "Conectado a Docker Registry al proyecto andonicacharreo.jfrog.io"
} else {
    "SI TE FALLA EL SCRIPT POR QUE DOCKER NO ESTÁ LOGADO HAZ ESTO:"
    #"NO ESTÁS CONECTADO A Docker Registry. Debes algo como: "
    "docker login -u andoni.ripoll@gmail.com andonicacharreo.jfrog.io"
    "luego le metes la password correcta: cmVmdGtuOjAxOjE3MzIyODU4OTQ6ZEVBMFlPYkdpTXY5eHI1aVpKS2t0bks2aGFG     ??"
    #exit
}

$ocStatusOutput = oc status
if ($ocStatusOutput -like '*In project development-arj*') {
    "Conectado a OpenShift al proyecto development-arj"
} else {
    "NO ESTÁS CONECTADO A OPEN SHIFT. Accede a :"
    "https://oauth-openshift.apps.ocpmovistar001.interactivos.int/login/Ldap?then=%2Foauth%2Fauthorize%3Fclient_id%3Dopenshift-browser-client%26idp%3DLdap%26redirect_uri%3Dhttps%253A%252F%252Foauth-openshift.apps.ocpmovistar001.interactivos.int%252Foauth%252Ftoken%252Fdisplay%26response_type%3Dcode"
    "Hacer algo como: "
    "oc login --token=sha256~Ae6-kSpqmuCFJ5x_8ME-CZ6t2BM8llXsBeJX2Y9roPU --server=https://api.ocpmovistar001.interactivos.int:6443"
    "pero con el token correcto"
    "Luego:"
    "oc create secret docker-registry secreto-docker-jfrog --docker-server=andonicacharreo.jfrog.io --docker-username=andoni.ripoll@gmail.com --docker-password=<la password de jfrog te quierooooo>"
    "oc secrets link default secreto-docker-jfrog --for=pull"
    exit
}

#$originPath = "bin\Debug\net5.0\publish"
#Donde apunta el dockerDesa.pubxml:
$originPath = "C:\Users\optiva\Downloads\POC.OTEL.20231020.Web.APartirGuillermo\bin\Release\net7.0\linux-x64\publish\"
$currentLocation =$pwd.path.tostring()
#$imageName = "andonidockerregistry.azurecr.io/poc_otel_web"
$version = Get-Date -format "yyyyMMdd-HHmm"
$imageName = "andonicacharreo.jfrog.io/docker/poc_otel_web:"+$version
#$imageName = "poc_otel_web"
"`n-->originPath = " + $originPath
"`n-->currentLocation = " + $currentLocation
"`n-->version    = " + $version 
"`n-->imageName  = " + $imageName 
Get-Location

#"`n-->Compilando: Resultados en compillation.output"
#"`n-->La variable de entorno env:MSBuild tiene que estar cargada. env:MSBuild = " + $env:MSBuild
#"Igual hay que hacer: [Environment]::SetEnvironmentVariable('MSBuild', 'C:\Program Files (x86)\Microsoft Visual Studio\<donde esté>\MSBuild.exe', 'Machine')"
dotnet publish POC.OTEL.20231020.Web.csproj /p:PublishProfile=Properties\PublishProfiles\FolderProfile.pubxml

#Get-ChildItem -Path $originPath | Foreach-object { write-output $_.FullName; Copy-item -path $_.FullName -Destination $ProgramPublishLocation -verbose -recurse -Force }
#Set-Location $ProgramPublishLocation
"`n-->cmd /r dir $originPath"
cmd /r dir $originPath

copy-item $currentLocation\NLog.dockerDes.config $originPath\NLog.config
copy-item $currentLocation\OTEL_DIAGNOSTICS.dockerDes.json $originPath\OTEL_DIAGNOSTICS.json

"`n-->Compress everything in a tar file"
cd $originPath
if (Test-Path poc.otel.web.tar.gz) { rm -fo poc.otel.web.tar.gz }
if (!(Test-Path C:\temp)) { mkdir C:\temp }
tar -cvzf c:\temp\poc.otel.web.tar.gz *
rm * -force -recurse 
copy-item C:\temp\poc.otel.web.tar.gz $originPath
copy-item $currentLocation\dockerfile $originPath\dockerfile
copy-item $currentLocation\pocTemplate.yaml $originPath\pocTemplate.yaml
mkdir log -f

"`n-->docker build"
#Al usar siempre nombres con versión distinta nunca necesito borrar la anterior
#docker image rm $imageName --force
docker build --tag $imageName .

"`n-->docker run. Sólo para la versión local"
# docker run --dns 10.201.100.15 --dns 10.201.100.16 --dns 8.8.8.8 -v "$($currentLocation)\$($originPath):C:\MessageConverter" -dit $imageName 
#docker run -v "$($originPath):\MessageConverter" -dit $imageName 
docker run --mount type=bind,source=C:\Logs\MessageConverter,target=/MessageConverter/log -dit $imageName

"`n-->docker push"
#docker login andonidockerregistry.azurecr.io -u andonidockerregistry -p cFfQ4WeJHng7pMYzJqmzVwt/EOk8V2NApDZlJ3fQ2i+ACRD9/qBr
docker push $imageName

"`n-->OpenShift"
"`n-->oc delete secret docker-registry secreto-docker-jfrog > ocdeletesecret.deleteme.out"
#oc delete secret docker-registry secreto-docker-jfrog > ocdeletesecret.deleteme.out
"---->El error que da el delete no hay que hacerle caso. "
"---> Esto para qué es?"
oc delete all -l app=poc_otel_web
#oc new-app $imageName
(Get-Content -path pocTemplate.yaml -Raw) -replace 'imageAndVersion',$imageName > poc.yaml
oc delete -f poc.yaml
"oc apply -f poc.yaml"
oc apply -f poc.yaml
"`n-->END Docker push y OpenShift"

docker container ls

cd $currentLocation

"`n-->Este curl se hace para que escriba sus primeras trazas al ser llamado"
Start-Sleep -Seconds 10
"cmd /r curl --insecure https://poc-otel-web.apps.ocpmovistar001.interactivos.int/hello"
cmd /r curl --insecure https://poc-otel-web.apps.ocpmovistar001.interactivos.int/hello

"`n-->Pulsa una tecla para cerrar"
#Set-Location "c:\"
cmd /c pause | out-null
