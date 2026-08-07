namespace ReportingAdmin.Domain.Audit;

// Marks an entity property for PII redaction before serialisation into OldValuesJson/NewValuesJson
[AttributeUsage(AttributeTargets.Property, AllowMultiple = false)]
public sealed class AuditRedactAttribute : Attribute { }
