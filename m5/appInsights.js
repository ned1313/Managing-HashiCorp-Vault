{
    backends: [ "appinsights-statsd" ],  // [Required] The Application Insighst StatsD backend
    aiInstrumentationKey: "AZURE_MONITOR_KEY",  // [Required] Your instrumentation key
    aiPrefix: "vault-vms",  // [Optional] Send only metrics with this prefix
    aiRoleName: "vault-server",  // [Optional] Add this role name context tag to every metric
    aiRoleInstance: "vault-vm-1",  // [Optional] Add this role instance context tag to every metric
    aiTrackStatsDMetrics: true,  // [Optional] Send StatsD internal metrics to Application Insights
}
