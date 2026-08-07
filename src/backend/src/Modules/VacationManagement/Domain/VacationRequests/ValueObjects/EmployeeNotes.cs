using VacationManagement.Domain.Common;

namespace VacationManagement.Domain.VacationRequests.ValueObjects;

// BR-005: notes are optional; max 500 characters
public sealed class EmployeeNotes : IEquatable<EmployeeNotes>
{
    public const int MaxLength = 500;

    public string? Value { get; }

    private EmployeeNotes(string? value) => Value = value;

    public static EmployeeNotes Empty { get; } = new(null);

    public static EmployeeNotes Create(string? value)
    {
        if (value is null)
            return Empty;

        var trimmed = value.Trim();
        if (trimmed.Length == 0)
            return Empty;

        if (trimmed.Length > MaxLength)
            throw new DomainException($"Notes must not exceed {MaxLength} characters.");

        return new(trimmed);
    }

    public bool IsEmpty => string.IsNullOrWhiteSpace(Value);

    public bool Equals(EmployeeNotes? other) => other is not null && Value == other.Value;
    public override bool Equals(object? obj) => obj is EmployeeNotes other && Equals(other);
    public override int GetHashCode() => Value?.GetHashCode() ?? 0;
    public override string ToString() => Value ?? string.Empty;
}
