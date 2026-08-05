// Fluent test data builder — tests/{BoundedContext}.UnitTests/Builders/MyEntityBuilder.cs
//
// Encapsulates default values so each test only overrides what it cares about.
// Use .Build() to get a valid domain object without repeating boilerplate.

namespace MyBoundedContext.UnitTests.Builders;

public class MyEntityBuilder
{
    private Guid _ownerId = Guid.NewGuid();
    private string _tenantId = "TENANT-001";
    private string _name = "Default Name";

    public MyEntityBuilder WithOwnerId(Guid ownerId)
    {
        _ownerId = ownerId;
        return this;
    }

    public MyEntityBuilder WithTenantId(string tenantId)
    {
        _tenantId = tenantId;
        return this;
    }

    public MyEntityBuilder WithName(string name)
    {
        _name = name;
        return this;
    }

    public MyEntity Build() =>
        MyEntity.Create(_ownerId, _tenantId, _name).Value;
}

// Usage in tests:
//
// var entity = new MyEntityBuilder().Build();                       // all defaults
// var entity = new MyEntityBuilder().WithName("Custom").Build();    // override one field
// var tenants = Enumerable.Range(1, 5)
//     .Select(i => new MyEntityBuilder().WithTenantId($"T-{i:000}").Build())
//     .ToList();
