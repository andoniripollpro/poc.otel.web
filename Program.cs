using Grpc.Core;
using OpenTelemetry;
using OpenTelemetry.Logs;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using System.Diagnostics;
using System.Runtime.Serialization;

internal class Program
{
    private const string ServiceName = "AndoniService";
    private static readonly ActivitySource ServiceActivitySource = new(ServiceName);
    private static Tracer tracer;
    private static ILogger<Program> logger;

    private static async Task Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddOpenTelemetry()
          .WithTracing(b =>
          {
              b
              .AddSource(ServiceName)
              .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(serviceName: ServiceName, serviceVersion: "1.0", serviceInstanceId: "S1"))
              .AddAspNetCoreInstrumentation()
              .AddOtlpExporter(options =>
              {
                  //options.Endpoint = new Uri("https://otlp-http.apps.ocpmovistar001.interactivos.int");
                  options.Endpoint = new Uri("http://collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4317");
                  options.Protocol = OpenTelemetry.Exporter.OtlpExportProtocol.Grpc;                  
              });
          });

        using var openTelemetry = Sdk.CreateTracerProviderBuilder()
            .AddSource(ServiceName)
            .AddOtlpExporter(options =>
            {
                //options.Endpoint = new Uri("https://otlp-http.apps.ocpmovistar001.interactivos.int");
                options.Endpoint = new Uri("http://collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4317");
                options.Protocol = OpenTelemetry.Exporter.OtlpExportProtocol.Grpc;
            })
            .Build();
        Program.tracer = openTelemetry.GetTracer("andoni-example-tracer");

        var loggerFactory = LoggerFactory.Create(builder =>
        {
            builder.AddOpenTelemetry(options =>
            {
                options.AddOtlpExporter(exporterOptions =>
                {                    
                    //options.Endpoint = new Uri("https://otlp-http.apps.ocpmovistar001.interactivos.int");
                    exporterOptions.Endpoint = new Uri("http://collector-opentelemetry-collector.opentelemetry.svc.cluster.local:4317");
                    exporterOptions.Protocol = OpenTelemetry.Exporter.OtlpExportProtocol.Grpc;
                });
            });
        });
        Program.logger = loggerFactory.CreateLogger<Program>();

        var app = builder.Build();
        
        app.MapGet("/hello", async () =>
        {            
            string msg = "Hello, World! Contact! Traces are arriving to Splunk";
            //activity?.SetTag("msg", msg);
            //activity?.Parent?.SetStatus(ActivityStatusCode.Error, "Mensaje controlado: Del padre");
            Log($"Carrascosa El mensaje de la web es: '{msg}'", LogType.Critical);
            Log($"Carrascosa El mensaje de la web es: '{msg}'", LogType.Error);
            Log($"Carrascosa El mensaje de la web es: '{msg}'", LogType.Warning);
            Log($"Carrascosa El mensaje de la web es: '{msg}'", LogType.Info);
            Log($"Carrascosa El mensaje de la web es: '{msg}'", LogType.Trace);
            SetState("Carrascosa: Mensaje controlado: Error. Algo me pasa!", ActivityStatusCode.Error);
            SetState("Carrascosa: Mensaje controlado: Otro mensaje mas", ActivityStatusCode.Ok);
            Log("Carrascosa 1", LogType.Error);
            Log("Carrascosa 2", LogType.Info);
            Trace("Carrascosa 3");
            Trace("Carrascosa 4");
            return msg;
        });

        app.Run();
    }

    private static void SetState(string message, ActivityStatusCode status = ActivityStatusCode.Unset)
    {
        using var activity = ServiceActivitySource.StartActivity("TEST.StarActivity", ActivityKind.Client);
        activity?.SetStatus(status, $"{message}");
    }

    private static void Trace(string message)
    {
        // Creo que esto nunca ha funcionado
        using (var telemetrySpan = tracer.StartActiveSpan("TEST.Trace"))
        {
            telemetrySpan?.AddEvent($"Trace33: {message}");
            // Termina la actividad
            telemetrySpan?.End();
        }
    }

    private static void Log(string message, LogType logType = LogType.Info )
    {
        switch (logType)
        {
            case LogType.Trace:
                Program.logger.LogTrace($"Log Trace: {message}");
                break;
            case LogType.Info:
                Program.logger.LogInformation($"Log Info: {message}");
                break;
            case LogType.Warning:
                Program.logger.LogWarning($"Log Warning: {message}");
                break;
            case LogType.Error:
                Program.logger.LogError($"Log Error: {message}");
                break;
            case LogType.Critical:
                Program.logger.LogCritical($"Log Critical: {message}");
                break;
            default:
                SetState($"ERROR EN EL LOG de este mensaje -> {message}", ActivityStatusCode.Error);
                break;
        }
    }

    enum LogType
    {
        Trace,
        Info,
        Warning,
        Error,
        Critical
    }
}